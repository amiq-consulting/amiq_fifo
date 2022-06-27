#!/usr/bin/python3

'''
Created on Mon Nov 22 11:05:12 EET 2021

@author: edaibr
'''

import traceback
import os

class bcolors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'
    
class logger:
    def __init__(self):
        self.disable_colors = False
        
    def printError(self, errorMsg):
        """
        This function is used to print errors.
        Error counter will be incremented on every error print.
        
        :param errorMsg: the string message to be printed
        :type errorMsg: string
        """
        p = traceback.extract_stack()
        last_call = p[-2]
        fileName = os.path.basename(last_call[0])
        lineNo = last_call[1]
        self.printMsg("ERROR", fileName, lineNo, errorMsg)
    
    
    def printWarning(self, warnMsg):
        """
        This function is used to print warnings.
        Warning counter will be incremented on every warning print.
        
        :param warnMsg: the string message to be printed
        :type warnMsg: string
        """
        p = traceback.extract_stack()
        last_call = p[-2]
        fileName = os.path.basename(last_call[0])
        lineNo = last_call[1]
        self.printMsg("WARNING", fileName, lineNo, warnMsg)
    
    
    def printInfo(self, msg):
        """
        This function is used to print information messages.
        
        :param errorMsg: the string message to be printed
        :type errorMsg: string
        """
        p = traceback.extract_stack()
        last_call = p[-2]
        fileName = os.path.basename(last_call[0])
        lineNo = last_call[1]
        self.printMsg("INFO", fileName, lineNo, msg)
        
    def printDebug(self, msg):
        """
        This function is used to print information messages.
        
        :param errorMsg: the string message to be printed
        :type errorMsg: string
        """
        p = traceback.extract_stack()
        last_call = p[-2]
        fileName = os.path.basename(last_call[0])
        lineNo = last_call[1]
        self.printMsg("DEBUG", fileName, lineNo, msg)
    
    def setDisableColors(self, value):
        self.disable_colors = value
        
    def printMsg(self, kind, fileName, lineNo, msg):
        """
        This function is used to print any kind of message
        
        :param kind: the kind of the message [ERROR, WARNING or INFO]
        :type kind: string
        :param fileName: the name of the file from where the message is printed
        :type fileName: string
        :param lineNo: line number where the message is located inside the fileName
        :type lineNo: integer
        :param msg: the string message to be printed
        :type msg: string
        """
        
        if kind == "INFO":
            color_start = bcolors.OKBLUE
        elif kind == "WARNING":
            color_start = bcolors.WARNING
        elif kind == "ERROR":
            color_start = bcolors.FAIL
        elif kind == "DEBUG":
            color_start = bcolors.OKCYAN
        else:
            raise ValueError("Please define color for kind:{}".format(kind))

        color_end   = bcolors.ENDC
        
        if self.disable_colors:
            color_start = ""
            color_end   = ""
        
        # flush option is required to flush the message to the console 
        # otherwise it would execute commands and then print statements which were issues before those commands
        print("{color_start}Run script {kind:<7}:[{file}@{line}]{color_end} - {msg}".format(color_start=color_start, color_end=color_end, kind=kind, file=fileName, line=lineNo, msg=msg), flush=True)
            

log = logger()
