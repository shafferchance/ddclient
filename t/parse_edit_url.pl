use Test::More;

eval { require 'ddclient'; } or BAIL_OUT($@);

my $host = "example.com";

sub test_setup {
    # This may be pointless, but is here for sanity of future testers since import happens in update logic
    ddclient::load_uri_escape();
    is(defined(&uri_escape), '', "uri_encode has been imported successfully");
}

subtest "simple_parse_url" => sub {
    test_setup();
    my $url = ddclient::parse_url("https://$host");
    is(%$url{'protocol'}, 'https', "URL protocol parsed correctly");
    is(%$url{'host'},$host, "URL host (domain) parsed correctedly");
    is(%$url{'path'},'/', "URL path is set to default /");
};

subtest "advanced_parse_url" => sub {
    test_setup();
    my $url = ddclient::parse_url("sftp://some.$host:8000/hello?user=thing&pass=never");
    is(%$url{'protocol'}, 'sftp', "URL protocol parsed correctly");
    is(%$url{'host'}, "some.$host", "URL host (domain) parsed correctly");
    is(%$url{'port'}, '8000', "URL port parsed correctly");
    is(%$url{'path'}, '/hello', "URL path parsed correctly");
    is(%$url{'query_string'}, 'user=thing&pass=never', "URL query_string parsed correctly");
    is(%{%$url{"query_string_map"}}{"user"}, 'thing', "URL query_string user extracted successfully");
    is(%{%$url{"query_string_map"}}{'pass'}, 'never', "URL query_string pass extracted successfully");
};

subtest "parse_url_throws_error" => sub {
    test_setup();
    eval {
        ddclient::parse_url("");
    };

    ok(defined($@), "URL parse error is thrown");
    like($@, qr/Invalid URL: Missing both protocol and host/, "URL parse error message is correct");
};

subtest "get_encoded_query_string" => sub {
    test_setup();

    my $url = ddclient::parse_url("sftp://some.$host:8000/hello?user=thing&pass=never");
    # The order is different since AWS requires things in alphabetical order
    is(ddclient::get_encoded_query_string($url), "pass=never&user=thing", "get_query_string works for simple query parameters");

    my $url2 = ddclient::parse_url("https://$host?a\$|s./=#hell0\%f&d*=\|\>\<\:\;\+&\@\{\}=\]\[\!\^\"'\\");

    is(
        ddclient::get_encoded_query_string($url2),
        '%40%7B%7D=%5D%5B%21%5E%22%27%5C&a%24%7Cs.%2F=%23hell0%25f&d%2A=%7C%3E%3C%3A%3B%2B',
        "get_query_string escapes as expected"
    );
};

subtest "encode_url_path" => sub {
    test_setup();

     is(
        ddclient::encode_url_path(
            # Here to make debugging easier I have prefixed the above query string map in a url format
            # we do expect that the / from the first key to NOT be encoded
            '/1a$|s./a/1#hell0/2f&d*/2|=><=:;+/3@{}/3][!^"\'\\/another.jpg'
        ),
        '/1a%24%7Cs./a/1%23hell0/2f%26d%2A/2%7C%3D%3E%3C%3D%3A%3B%2B/3%40%7B%7D/3%5D%5B%21%5E%22%27%5C/another.jpg',
        'encode_url_path escapes as expected'
    );

    is(
        ddclient::encode_url_path(
            '/'
        ),
        '/',
        'encode_url_path works for basic path'
    );

    is(
        ddclient::encode_url_path(
            '/examplebucket/myphoto.jpg'
        ),
        '/examplebucket/myphoto.jpg',
        'encode_url_path / aren\'t encoded'
    )
};

subtest "get_full_url" => sub {
    test_setup();

    my $basic = ddclient::parse_url("sftp://some.$host:8000/hello?user=thing&pass=never");
    is(
        ddclient::get_full_url($basic),
        "sftp://some.$host:8000/hello?pass=never&user=thing",
        "get_full_url basic url works"
    );

    # I could reassign here but for clarity I won't 
    my $advanced = ddclient::parse_url('https://'.$host.'/s0>/d#?@@$ym=%*%&normal=false');
    is (
        ddclient::get_full_url($advanced),
        "https://$host/s0%3E/d%23?%40%40%24ym=%25%2A%25&normal=false",
        "get_full_url encodes correct"
    );
};

done_testing();