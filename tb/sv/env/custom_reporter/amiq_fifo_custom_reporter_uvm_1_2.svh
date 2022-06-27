//----------------------------------------------------------------------
// Created by edaibr on Fri Feb 11 13:53:21 EET 2022
// Company name: amiq
// Project name: fifo
// Additional details:
// none
//----------------------------------------------------------------------


/*
 * Overwrite the default reporter to get more readable messages
 */
class amiq_fifo_custom_reporter extends uvm_default_report_server;
  // stores an ASCII code for a file path separator
  byte amiq_common_separator_code;

  // stores the simulation time in the form of a string
  string simulation_time;

  /*
   * Constructor function for the custom reporter
   * @see uvm_pkg::uvm_object.new
   * @param name -
   */
  function new(string name = "amiq_fifo_custom_reporter");
    string amiq_common_separator = "/";
    super.new();

    amiq_common_separator_code = amiq_common_separator.getc(0);

    $system("date +%s%N> sim_start_time.date");
  endfunction

  // Overwrite the default compose message
  virtual function string compose_report_message(uvm_report_message report_message, string report_object_name = "");

    uvm_severity severity = report_message.get_severity();
    
    string       name = report_message.get_name();
    string       id = report_message.get_id();
    string       message = report_message.get_message();
    string       filename = report_message.get_filename();
    int          line = report_message.get_line();

    real start_time;
    real end_time;

    $system("date +%s%N> sim_fail_time.date");

    if(severity == UVM_ERROR || severity == UVM_FATAL) begin
      start_time = read_time_from_file("sim_start_time.date");
      end_time   = read_time_from_file("sim_fail_time.date");

      simulation_time = get_sim_duration(end_time - start_time);

      return $sformatf("%s @ %0d ns [%s:%0d][%s] : %s \n %s",
        severity.name(), $time, get_filename(filename), line, id, message, simulation_time);
    end

    return $sformatf("%s @ %0d ns [%s:%0d][%s]: %s",
      severity.name(), $time, get_filename(filename), line, id, message);
  endfunction

  // Gets the file name without the path
  function string get_filename(const ref string str);
    int len = str.len();
    int file_start_pos;

    if (len > 0) begin
      for(int i=len-1; i>=0; i--)
        if (str.getc(i) == amiq_common_separator_code) begin
          file_start_pos = i+1;
          break;
        end

      get_filename = str.substr(file_start_pos, len-1);
    end
  endfunction

  function real read_time_from_file(string file_name);
    // Output string after reading it from file
    string output_string;

    // Variables used to retain the results of fopen and fgets methods
    integer f_open;

    // Open file in order to read current date
    f_open = $fopen(file_name, "r");

    // Read the date from file and put it into a string
    void'($fgets(output_string, f_open));

    // Convert the string to a real number
    void'($sscanf(output_string,"%f",read_time_from_file));

    // Close the file
    $fclose(f_open);

    // Convert time in seconds
    read_time_from_file = read_time_from_file / 1_000_000_000;
  endfunction

  function string get_sim_duration(real time_span);
    real         seconds;
    int unsigned minutes;
    int unsigned hours;
    int unsigned days;

    if(time_span < 60)
      seconds = time_span;
    else begin
      seconds = time_span - ((int'(time_span) / 60) * 60);
      minutes = int'(time_span) / 60;

      if(minutes >= 60) begin
        hours   = minutes / 60;
        minutes = minutes % 60;

        if(hours >= 24) begin
          days  = hours / 24;
          hours = hours % 24;
        end
      end
    end
    get_sim_duration = $sformatf(">>> Simulation took: %0dd %0dh %0dm %0ds", days, hours, minutes, seconds);
  endfunction
endclass
