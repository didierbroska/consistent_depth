"""
Params parsing for app cli.
"""

import argparse
import logging
from os import makedirs
from os.path import dirname, isdir, isfile, join, abspath


class AppParams:
    """
    Application entry parses all arguments and configure application.
    """

    def __init__(self):
        self.__parser = argparse.ArgumentParser()

    def parse(self):
        # Start parsing
        self.__main_args()
        self.__video_args()

        # processing arguments
        self.args = self.__parser.parse_args()
        self.__increase_verbosity()
        self.__debug_mode()

        self.__frames()
        self.__input()
        self.__output()

        return self.args

    def __increase_verbosity(self):
        """
        Add Info logs.
        """
        if self.args.verbose:
            logging.basicConfig(format="%(message)s", level=logging.INFO)

    def __debug_mode(self):
        """
        Activate debug mode.
        """
        if self.args.debug:
            logging.basicConfig(
                format="%(asctime)s - %(levelname)s : %(message)s",
                level=logging.DEBUG,
            )
        logging.debug("Debug mode is activated.")

    def __frames(self):
        """
        Parsing frames arguments
        """
        # remove separator
        if self.args.frames is not None:
            self.args.frames.remove(",")
            # convert in int value
            self.args.frames = [int(f) for f in self.args.frames]
            # test values
            if self.args.frames[0] > self.args.frames[1]:
                raise ValueError(
                    "The first frame can't be less than the last !"
                )
            start, end = self.args.frames
            logging.debug(
                "Frames extracted will be start {} to {}.".format(start, end)
            )
        logging.debug("All frames will be extracted.")

    def __input(self):
        if not isfile(self.args.input):
            raise FileNotFoundError(self.args.input)
        logging.debug(
            "Input file selected is : {}".format(abspath(self.args.input))
        )

    def __output(self):
        if self.args.output is None:
            self.args.output = join(dirname(self.args.input), "results")
        if not isdir(self.args.output):
            logging.info(
                "Created directory : {}".format(abspath(self.args.output))
            )
            makedirs(self.args.output, exist_ok=True)
        logging.debug(
            "Output folder selected is : {}".format(abspath(self.args.output))
        )

    def __main_args(self):
        """
        Main entry point for arguments
        """

        self.__parser.add_argument(
            "-d", "--debug", help="Enable debug mode.", action="store_true"
        )

        self.__parser.add_argument(
            "-v", "--verbose", help="Increase verbosity.", action="store_true"
        )

        self.__parser.add_argument(
            "-i",
            "--input",
            help="Input video path.",
            type=str,
            metavar="[PATH]",
            required=True,
        )

        self.__parser.add_argument(
            "-o",
            "--output",
            help="Output path for results",
            type=str,
            metavar="[PATH]",
        )

    def __video_args(self):
        """
        All arguments relative to video setup.
        """
        self.__parser.add_argument(
            "-f",
            "--frames",
            help="Specify start and end frames. Eg. 5,500",
            type=list,
            metavar="START,END",
        )
