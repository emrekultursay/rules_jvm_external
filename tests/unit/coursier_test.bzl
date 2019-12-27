load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load(
    "//:coursier.bzl",
    "add_netrc_entries_from_mirror_urls",
    "extract_netrc_from_auth_url",
    "get_netrc_lines_from_entries",
    "get_coursier_cache_or_default",
    "remove_auth_from_url",
    "split_url",
    infer = "infer_artifact_path_from_primary_and_repos",
)

ALL_TESTS = []

def add_test(test_impl_func):
    test = unittest.make(test_impl_func)
    ALL_TESTS.append(test)
    return test

def _infer_doc_example_test_impl(ctx):
    env = unittest.begin(ctx)
    asserts.equals(
        env,
        "group/path/to/artifact/file.jar",
        infer("http://a:b@c/group/path/to/artifact/file.jar", ["http://c"]),
    )
    return unittest.end(env)

infer_doc_example_test = add_test(_infer_doc_example_test_impl)

def _infer_basic_test_impl(ctx):
    env = unittest.begin(ctx)
    asserts.equals(
        env,
        "group/artifact/version/foo.jar",
        infer("https://base/group/artifact/version/foo.jar", ["https://base"]),
    )
    asserts.equals(
        env,
        "group/artifact/version/foo.jar",
        infer("http://base/group/artifact/version/foo.jar", ["http://base"]),
    )
    return unittest.end(env)

infer_basic_test = add_test(_infer_basic_test_impl)

def _infer_auth_basic_test_impl(ctx):
    env = unittest.begin(ctx)
    asserts.equals(
        env,
        "group1/artifact/version/foo.jar",
        infer("https://a@c/group1/artifact/version/foo.jar", ["https://a:b@c"]),
    )
    asserts.equals(
        env,
        "group2/artifact/version/foo.jar",
        infer("https://a@c/group2/artifact/version/foo.jar", ["https://a@c"]),
    )
    asserts.equals(
        env,
        "group3/artifact/version/foo.jar",
        infer("https://a@c/group3/artifact/version/foo.jar", ["https://c"]),
    )
    return unittest.end(env)

infer_auth_basic_test = add_test(_infer_auth_basic_test_impl)

def _infer_leading_repo_miss_test_impl(ctx):
    env = unittest.begin(ctx)
    asserts.equals(
        env,
        "group/artifact/version/foo.jar",
        infer("https://a@c/group/artifact/version/foo.jar", ["https://a:b@c/missubdir", "https://a:b@c"]),
    )
    return unittest.end(env)

infer_leading_repo_miss_test = add_test(_infer_leading_repo_miss_test_impl)

def _infer_repo_trailing_slash_test_impl(ctx):
    env = unittest.begin(ctx)
    asserts.equals(
        env,
        "group/artifact/version/foo.jar",
        infer("https://a@c/group/artifact/version/foo.jar", ["https://a:b@c"]),
    )
    asserts.equals(
        env,
        "group/artifact/version/foo.jar",
        infer("https://a@c/group/artifact/version/foo.jar", ["https://a:b@c/"]),
    )
    asserts.equals(
        env,
        "group/artifact/version/foo.jar",
        infer("https://a@c/group/artifact/version/foo.jar", ["https://a:b@c//"]),
    )
    return unittest.end(env)

infer_repo_trailing_slash_test = add_test(_infer_repo_trailing_slash_test_impl)

def _remove_auth_basic_test_impl(ctx):
    env = unittest.begin(ctx)
    asserts.equals(
        env,
        "https://c1",
        remove_auth_from_url("https://a:b@c1"),
    )
    return unittest.end(env)

remove_auth_basic_test = add_test(_remove_auth_basic_test_impl)

def _remove_auth_basic_with_path_test_impl(ctx):
    env = unittest.begin(ctx)
    asserts.equals(
        env,
        "https://c1/some/random/path",
        remove_auth_from_url("https://a:b@c1/some/random/path"),
    )
    return unittest.end(env)

remove_auth_basic_with_path_test = add_test(_remove_auth_basic_with_path_test_impl)

def _remove_auth_only_user_test_impl(ctx):
    env = unittest.begin(ctx)
    asserts.equals(
        env,
        "https://c1",
        remove_auth_from_url("https://a@c1"),
    )
    return unittest.end(env)

remove_auth_only_user_test = add_test(_remove_auth_only_user_test_impl)

def _remove_auth_noauth_noop_test_impl(ctx):
    env = unittest.begin(ctx)
    asserts.equals(
        env,
        "https://c1",
        remove_auth_from_url("https://c1"),
    )
    return unittest.end(env)

remove_auth_noauth_noop_test = add_test(_remove_auth_noauth_noop_test_impl)

def _split_url_basic_test_impl(ctx):
    env = unittest.begin(ctx)
    asserts.equals(
        env,
        ("https", ["c1"]),
        split_url("https://c1"),
    )
    return unittest.end(env)

split_url_basic_test = add_test(_split_url_basic_test_impl)

def _split_url_basic_auth_test_impl(ctx):
    env = unittest.begin(ctx)
    asserts.equals(
        env,
        ("https", ["a:b@c1"]),
        split_url("https://a:b@c1"),
    )
    asserts.equals(
        env,
        ("https", ["a@c1"]),
        split_url("https://a@c1"),
    )
    return unittest.end(env)

split_url_basic_auth_test = add_test(_split_url_basic_auth_test_impl)

def _split_url_with_path_test_impl(ctx):
    env = unittest.begin(ctx)
    asserts.equals(
        env,
        ("https", ["c1", "some", "path"]),
        split_url("https://c1/some/path"),
    )
    return unittest.end(env)

split_url_with_path_test = add_test(_split_url_with_path_test_impl)

def _extract_netrc_from_auth_url_noop_test_impl(ctx):
    env = unittest.begin(ctx)
    asserts.equals(
        env,
        {},
        extract_netrc_from_auth_url("https://c1"),
    )
    asserts.equals(
        env,
        {},
        extract_netrc_from_auth_url("https://c2/useless@inurl"),
    )
    return unittest.end(env)

extract_netrc_from_auth_url_noop_test = add_test(_extract_netrc_from_auth_url_noop_test_impl)

def _extract_netrc_from_auth_url_with_auth_test_impl(ctx):
    env = unittest.begin(ctx)
    asserts.equals(
        env,
        {"machine": "c", "login": "a", "password": "b"},
        extract_netrc_from_auth_url("https://a:b@c"),
    )
    asserts.equals(
        env,
        {"machine": "c", "login": "a", "password": "b"},
        extract_netrc_from_auth_url("https://a:b@c/some/other/stuff@thisplace/for/testing"),
    )
    asserts.equals(
        env,
        {"machine": "c", "login": "a", "password": None},
        extract_netrc_from_auth_url("https://a@c"),
    )
    asserts.equals(
        env,
        {"machine": "c", "login": "a", "password": None},
        extract_netrc_from_auth_url("https://a@c/some/other/stuff@thisplace/for/testing"),
    )
    return unittest.end(env)

extract_netrc_from_auth_url_with_auth_test = add_test(_extract_netrc_from_auth_url_with_auth_test_impl)

def _extract_netrc_from_auth_url_at_in_password_test_impl(ctx):
    env = unittest.begin(ctx)
    asserts.equals(
        env,
        {"machine": "c", "login": "a", "password": "p@ssword"},
        extract_netrc_from_auth_url("https://a:p@ssword@c"),
    )
    return unittest.end(env)

extract_netrc_from_auth_url_at_in_password_test = add_test(_extract_netrc_from_auth_url_at_in_password_test_impl)

def _add_netrc_entries_from_mirror_urls_noop_test_impl(ctx):
    env = unittest.begin(ctx)
    asserts.equals(
        env,
        {},
        add_netrc_entries_from_mirror_urls({}, ["https://c1", "https://c1/something@there"]),
    )
    return unittest.end(env)

add_netrc_entries_from_mirror_urls_noop_test = add_test(_add_netrc_entries_from_mirror_urls_noop_test_impl)

def _add_netrc_entries_from_mirror_urls_basic_test_impl(ctx):
    env = unittest.begin(ctx)
    asserts.equals(
        env,
        {"c1": {"a": "b"}},
        add_netrc_entries_from_mirror_urls({}, ["https://a:b@c1"]),
    )
    asserts.equals(
        env,
        {"c1": {"a": "b"}},
        add_netrc_entries_from_mirror_urls(
            {"c1": {"a": "b"}},
            ["https://a:b@c1"],
        ),
    )
    return unittest.end(env)

add_netrc_entries_from_mirror_urls_basic_test = add_test(_add_netrc_entries_from_mirror_urls_basic_test_impl)

def _add_netrc_entries_from_mirror_urls_multi_login_ignored_test_impl(ctx):
    env = unittest.begin(ctx)
    asserts.equals(
        env,
        {"c1": {"a": "b"}},
        add_netrc_entries_from_mirror_urls({}, ["https://a:b@c1", "https://a:b2@c1", "https://a2:b3@c1"]),
    )
    asserts.equals(
        env,
        {"c1": {"a": "b"}},
        add_netrc_entries_from_mirror_urls(
            {"c1": {"a": "b"}},
            ["https://a:b@c1", "https://a:b2@c1", "https://a2:b3@c1"],
        ),
    )
    return unittest.end(env)

add_netrc_entries_from_mirror_urls_multi_login_ignored_test = add_test(_add_netrc_entries_from_mirror_urls_multi_login_ignored_test_impl)

def _add_netrc_entries_from_mirror_urls_multi_case_test_impl(ctx):
    env = unittest.begin(ctx)
    asserts.equals(
        env,
        {
            "foo": {"bar": "baz"},
            "c1": {"a1": "b1"},
            "c2": {"a2": "b2"},
        },
        add_netrc_entries_from_mirror_urls(
            {"foo": {"bar": "baz"}},
            ["https://a1:b1@c1", "https://a2:b2@c2", "https://a:b@c1", "https://a:b2@c1", "https://a2:b3@c1"],
        ),
    )
    return unittest.end(env)

add_netrc_entries_from_mirror_urls_multi_case_test = add_test(_add_netrc_entries_from_mirror_urls_multi_case_test_impl)

def _get_netrc_lines_from_entries_noop_test_impl(ctx):
    env = unittest.begin(ctx)
    asserts.equals(
        env,
        [],
        get_netrc_lines_from_entries({}),
    )
    return unittest.end(env)

get_netrc_lines_from_entries_noop_test = add_test(_get_netrc_lines_from_entries_noop_test_impl)

def _get_netrc_lines_from_entries_basic_test_impl(ctx):
    env = unittest.begin(ctx)
    asserts.equals(
        env,
        ["machine c", "login a", "password b"],
        get_netrc_lines_from_entries({
            "c": {"a": "b"},
        }),
    )
    return unittest.end(env)

get_netrc_lines_from_entries_basic_test = add_test(_get_netrc_lines_from_entries_basic_test_impl)

def _get_netrc_lines_from_entries_no_pass_test_impl(ctx):
    env = unittest.begin(ctx)
    asserts.equals(
        env,
        ["machine c", "login a"],
        get_netrc_lines_from_entries({
            "c": {"a": ""},
        }),
    )
    return unittest.end(env)

get_netrc_lines_from_entries_no_pass_test = add_test(_get_netrc_lines_from_entries_no_pass_test_impl)

def _get_netrc_lines_from_entries_multi_test_impl(ctx):
    env = unittest.begin(ctx)
    asserts.equals(
        env,
        [
            "machine c",
            "login a",
            "password b",
            "machine c2",
            "login a2",
            "password p@ssword",
        ],
        get_netrc_lines_from_entries({
            "c": {"a": "b"},
            "c2": {"a2": "p@ssword"},
        }),
    )
    return unittest.end(env)

get_netrc_lines_from_entries_multi_test = add_test(_get_netrc_lines_from_entries_multi_test_impl)

def _mock_repo_path(path):
    if path.startswith("/"):
        return path
    else:
        return "/mockroot/" + path

def _get_coursier_cache_or_default_disabled_test(ctx):
    env = unittest.begin(ctx)
    mock_environ = {
        "COURSIER_CACHE": _mock_repo_path("/does/not/matter")
    }
    asserts.equals(
        env,
        "v1",
        get_coursier_cache_or_default(mock_environ, False)
    )
    return unittest.end(env)

get_coursier_cache_or_default_disabled_test = add_test(_get_coursier_cache_or_default_disabled_test)

def _get_coursier_cache_or_default_enabled_with_default_location_test(ctx):
    env = unittest.begin(ctx)
    mock_environ = {}
    asserts.equals(
        env,
        "v1",
        get_coursier_cache_or_default(mock_environ, True)
    )
    return unittest.end(env)

get_coursier_cache_or_default_enabled_with_default_location_test = add_test(_get_coursier_cache_or_default_enabled_with_default_location_test)

def _get_coursier_cache_or_default_enabled_with_custom_location_test(ctx):
    env = unittest.begin(ctx)
    mock_environ = {
        "COURSIER_CACHE": _mock_repo_path("/custom/location")
    }
    asserts.equals(
        env,
        "/custom/location",
        get_coursier_cache_or_default(mock_environ, True)
    )
    return unittest.end(env)

get_coursier_cache_or_default_enabled_with_custom_location_test = add_test(_get_coursier_cache_or_default_enabled_with_custom_location_test)

def coursier_test_suite():
    unittest.suite(
        "coursier_tests",
        *ALL_TESTS
    )