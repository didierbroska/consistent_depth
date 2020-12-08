"""
Test parsing arguments entry points.
"""

import os.path
import sys
from argparse import Namespace
from os import rmdir

import pytest

from consistent_depth.cli.params import AppParams


@pytest.mark.parametrize(
    ("input, debug, verbose, frames, nb_frames, output, folder"),
    (
        ("-i", "-d", "-v", "-f", "1,5", "-o", "foo"),
        (
            "--input",
            "--debug",
            "--verbose",
            "--frames",
            "1,5",
            "--output",
            "foo",
        ),
    ),
)
def test_args(
    video_file1, input, debug, verbose, frames, nb_frames, output, folder
):
    """
    Test logging in entry app parser arguments.
    """
    sys.argv = ["app"]

    # Just input and gen output
    sys.argv.extend([input, video_file1])
    assert AppParams().parse() == Namespace(
        input=video_file1,
        debug=False,
        verbose=False,
        frames=None,
        output=os.path.join(os.path.dirname(video_file1), "results"),
    )

    # add debug and verbose
    sys.argv.extend([debug, verbose])
    assert AppParams().parse() == Namespace(
        input=video_file1,
        debug=True,
        verbose=True,
        frames=None,
        output=os.path.join(os.path.dirname(video_file1), "results"),
    )

    # Add frames
    sys.argv.extend([frames, nb_frames])
    assert AppParams().parse() == Namespace(
        input=video_file1,
        debug=True,
        verbose=True,
        frames=[1, 5],
        output=os.path.join(os.path.dirname(video_file1), "results"),
    )

    # Custom output
    sys.argv.extend([output, folder])
    assert AppParams().parse() == Namespace(
        input=video_file1,
        debug=True,
        verbose=True,
        frames=[1, 5],
        output="foo",
    )
    assert os.path.isdir("foo")
    rmdir("foo")


@pytest.mark.parametrize(
    ("input, filename,frames, nb_frames"),
    (("-i", "foo", "-f", "7,5"), ("--input", "foo", "--frames", "8,2")),
)
def test_raises_args(video_file1, input, filename, frames, nb_frames):
    """
    Test raising in arguments parser.
    """
    sys.argv = ["app"]
    with pytest.raises(SystemExit):
        AppParams().parse()

    sys.argv.extend([input, video_file1])
    sys.argv.extend([frames, nb_frames])
    with pytest.raises(ValueError):
        AppParams().parse()

    sys.argv = ["app"]
    sys.argv.extend([input, "foo"])
    with pytest.raises(FileNotFoundError):
        AppParams().parse()
