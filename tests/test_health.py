from kloros.utils.health import ping


def test_ping():
    assert ping() == "pong"
