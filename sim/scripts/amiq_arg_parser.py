#!/usr/bin/python3

'''
Created on Mon Nov 22 11:05:12 EET 2021

@author: edaibr
'''

import os
from scripts.amiq_logger import log

class scriptArgs:
    def __init__(self):
        self.parseScriptArguments()
        self.printDetails()
        
    def parseScriptArguments(self):
       import argparse
       import sys
       
       global args
       projPath = os.getenv("PROJ_HOME")
       
       if projPath == None:
           raise ValueError("Please define the PROJ_HOME environment variable before running the script")
       elif not os.path.isdir(projPath):
            log.printError("The provided PROJ_HOME path is not a directory path: " + projPath)
       
       parser = argparse.ArgumentParser(description="Process arguments to the %s script" % sys.argv[0])
       parser.add_argument('-tool', dest="tool", default="xcelium", choices=["xcelium", "vcs", "questa"], action="store", help="Provide a simulator (xcelium|vcs|questa) for compiling and running (default=xcelium)")
       parser.add_argument('-test', dest="testname", default="amiq_mux_random_test", action="store", help="Provide a test name to be simulated (default=amiq_mux_random_test)")
       parser.add_argument('-seed', dest="seed", default="1", action="store", help="Provide a seed for the test")
       parser.add_argument('-bit', dest="architecture", default="64", choices=["32","64"], action="store", help="Specify what architecture to use")
       parser.add_argument('-gui', dest="gui_mode", default=False, action="store_true", help="Run in GUI mode")
       parser.add_argument('-debug', dest="debug", default=False, action="store_true", help="Print debug messages")
       parser.add_argument('-mode', dest="mode", default="compile", choices=["compile","run","compile_and_run","c", "r", "cr"], action="store", help="Specify what to do with the source files [compile/run/compile_and_run] [c/r/cr]")
       parser.add_argument('-top', dest="top", default="amiq_fifo_tb_top", action="store", help="Specify the name of the top module.")
       parser.add_argument('-snapshot', dest="snapshot", default="none", action="store", help="Specify the name of the snapshot directory")
       parser.add_argument('-proj_path', dest="proj_path", default=os.environ['PROJ_HOME'], action="store", help="Specify the root folder for the project")
       parser.add_argument('-verbosity', dest="verbosity", choices=["NONE", "LOW", "MEDIUM", "HIGH", "DEBUG"], default="LOW", action="store", help="Specify the verbosity of the simulation")
       parser.add_argument('-custom_reporter', dest="custom_reporter", default=False, action="store_true", help="Use a custom uvm report server. Messages should be easier to read.")
       parser.add_argument('-stop', dest="stop_on_first_error", default=False, action="store_true", help="Stop simulation at first uvm_error")
       parser.add_argument('-disable_coverage', dest="disable_coverage", default=False, action="store_true", help="Disable coverage collection")
       parser.add_argument('-custom_wave', dest="custom_wave", default=False, action="store_true", help="Open custom waves")
       parser.add_argument('-full_wave_dump', dest="full_wave_dump", default=False, action="store_true", help="Probe all signals recursively")
       parser.add_argument('-simdir', dest="simdir", default="work", action="store", help="Specify the simulation directory (default=work)")
       parser.add_argument('-override', dest="override", default=False, action="store_true", help="Clean up the simulation directory")
       parser.add_argument('-extra_args', dest="extra_args", default="", action="store", help="Add extra arguments to be passed to the simulator")
       parser.add_argument('-disable_colors', dest="disable_colors", default=False, action="store_true", help="Disable message coloring")
       parser.add_argument('-autorun', dest="autorun", default=False, action="store_true", help="Enable automatic run of the test")
       parser.add_argument('-lang', dest="lang", default="sv", choices=["sv","e"], action="store", help="Verification language to be used by this simulation")
       
       self.args = parser.parse_args()
       
    def printDetails(self):
       #disable message coloring
       log.setDisableColors(self.args.disable_colors)
           
       log.printInfo("====================================================================")
       log.printInfo("Simulator      : {}".format(self.args.tool))
       log.printInfo("Architecture   : {} bit".format(self.args.architecture))
       log.printInfo("Mode           : {}".format(self.args.mode))
       log.printInfo("Test name      : {}".format(self.args.testname))
       log.printInfo("Seed           : {}".format(self.args.seed))
       log.printInfo("GUI mode       : {}".format(self.args.gui_mode))
       if self.args.snapshot != "none":
           log.printInfo("Snapshot       :{}".format(self.args.snapshot))
       log.printInfo("Top module     : {}".format(self.args.top))
       log.printInfo("Language       : {}".format(self.args.lang))
       log.printInfo("====================================================================")

    def getArgs(self):
        return self.args

args = scriptArgs().getArgs()
