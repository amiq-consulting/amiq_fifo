import os
import subprocess
from _operator import add
from _ast import Add
# from amiq_utils import *
from scripts.amiq_logger import log
from scripts.amiq_arg_parser import args

def add_option(cmd, option):
    cmd = cmd + " " + option
    return cmd

def run_linux_command(cmd):
    if args.debug:
        log.printDebug("Running command: {}".format(cmd))
    os.system(cmd)
    
def common_arguments(cmd):
    cmd = add_option(cmd, "+UVM_TESTNAME=" + args.testname)
    cmd = add_option(cmd, "+UVM_VERBOSITY=" + args.verbosity)
    
    if args.stop_on_first_error:
        if args.tool == "vcs":
            cmd = add_option(cmd, '+ntb_stop_on_error')
        else:
            cmd = add_option(cmd, '+uvm_set_action="*,_ALL_,UVM_ERROR,UVM_DISPLAY|UVM_STOP"')
    
    if args.gui_mode:
        cmd = add_option(cmd, "-gui")
    
    if args.custom_reporter:
        cmd = add_option(cmd, "+USE_CUSTOM_UVM_REPORTER=1")

    return cmd

def compile_xcelium():
    cmd = "xrun -c"
    cmd = add_option(cmd, "-f " + args.proj_path+"/sim/xcelium.options")
    
    if args.snapshot != "none":
        cmd = add_option(cmd, "-xmlibdirpath " + args.snapshot)
            
    run_linux_command(cmd)

def create_tcl_file(fname):
    f = open(fname, "w")
    
    if args.lang == "e":
        f.write('sn "@{path}/sim/specman.ecom {verbosity};"\n'.format(path=args.proj_path, verbosity=args.verbosity))
        
    if args.full_wave_dump:
        f.write("run 1ps;\n")
        f.write("database -open waves;\n")
        f.write("probe -create amiq_fifo_tb_top -all -depth all -database waves;\n")
    if args.gui_mode and args.custom_wave:
        f.write("simvision -input {}/sim/xcelium_signals.svwf;\n".format(args.proj_path))
    if args.autorun:
        f.write("run;\n")
    f.close()
    
def run_xcelium():
    fname="xcelium_run_options.tcl"
    create_tcl_file(fname)
    
    cmd = "xrun"
    
    cmd = add_option(cmd, "-f " + args.proj_path+"/sim/xcelium.options")
    cmd = common_arguments(cmd)
    cmd = add_option(cmd, "-seed " + args.seed)
    
    if args.lang == "e":
        cmd = add_option(cmd, "-snload "+args.testname)
    else:
        if args.snapshot != "none":
            cmd = add_option(cmd, "-R -xmlibdirpath " + args.snapshot)
        
        if args.disable_coverage:
            cmd = add_option(cmd, "-covnomodeldump")
        
    cmd = add_option(cmd, "-input "+fname)
    cmd = add_option(cmd, args.extra_args)
    
    run_linux_command(cmd)
    
def compile_vcs():
    if args.lang == "e":
        log.printError("VCS does not support e-language!")
    else:
        fname="vcs_run_options.do"
        f = open(fname, "w")
        if args.autorun:
            f.write("run")
        f.close()
        
        cmd = "vcs"
        cmd = common_arguments(cmd)
        cmd = add_option(cmd, "-ntb_opts uvm")
        cmd = add_option(cmd, "-f " + args.proj_path+"/sim/vcs.options")
        cmd = add_option(cmd, "+ntb_random_seed="+args.seed)
        if args.architecture == "64":
            cmd = add_option(cmd, "-full64")
        
        cmd = add_option(cmd, args.extra_args)
    #     cmd = add_option(cmd, "+plusarg_save")
    #     cmd = add_option(cmd, "-i "+fname)
         
        if args.gui_mode:
            cmd = add_option(cmd, "-gui")
            
        run_linux_command(cmd)
    
def run_vcs():
    if args.lang == "e":
        log.printError("VCS does not support e-language!")
    else:
        cmd = "./simv"
        cmd = common_arguments(cmd)
        run_linux_command(cmd)
    
def compile_questa():
    if args.lang == "e":
        log.printError("QuestaSim does not support e-language!")
    else:
        run_linux_command("vlib work")
        run_linux_command("vlog -f "  + args.proj_path+"/sim/questa.options")
    
def run_questa():
    if args.lang == "e":
        log.printError("QuestaSim does not support e-language!")
    else:
        fname="vsim_run_options.do"
        f = open(fname, "w")
        if args.autorun:
            f.write("run -all")
        f.close()
        
        cmd = "vsim"
        cmd = common_arguments(cmd)
        cmd = add_option(cmd, "-"+args.architecture)
        cmd = add_option(cmd, args.top)
        cmd = add_option(cmd,"-sv_seed " + args.seed)
        cmd = add_option(cmd, args.extra_args)
        
        if args.gui_mode:
            cmd = add_option(cmd,"-gui")
            
            if args.custom_wave:
                cmd = add_option(cmd, "-do "+args.proj_path+"/sim/questa_wave.do")
        else:
            cmd = add_option(cmd,"-batch")
        
        cmd = add_option(cmd, "-do {}".format(fname))
        
        run_linux_command(cmd)
    
    
def compile_and_run():
    log.printInfo("Using " + args.tool)
    
    if args.mode in ["c", "compile", "cr", "compile_and_run"]:
        log.printInfo("Start Compiling")
        if args.tool == "xcelium":
            compile_xcelium()
        elif args.tool == "vcs":
            compile_vcs()
        elif args.tool == "questa":
            compile_questa()
    if args.mode in ["r", "run", "cr", "compile_and_run"]:
        log.printInfo("Start Running")
        if args.tool == "xcelium":
            run_xcelium()
        elif args.tool == "vcs":
            run_vcs()
        elif args.tool == "questa":
            run_questa()
            
def runner():
    path = ""

    # for regression append the regression folder path
    if args.snapshot != "none":
        path = args.snapshot + args.simdir
    else:
        if args.simdir[0] == "/":
            path = args.simdir
        else:
            path = args.proj_path + "/sim/" + args.simdir
    
    # clean up folder
    if args.override:
        log.printInfo("[Clean up] Deleting folder " + path)
        run_linux_command("rm -rf " + path)

    run_linux_command("mkdir -p " + path)
    
    if os.path.isdir(path):
        os.chdir(path)
    else:
        logger.printError("The provided path is not a directory path: " + path)
        
    compile_and_run()
