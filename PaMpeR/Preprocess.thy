(*  Title:      Preprocess.thy
    Author:     Yutaka Nagashima, CIIRC, CTU

    The structure, "Preprocess", re-organizes the raw output generated by the feature extractor of
    PaMpeR. Preprocess inputs the file "Database", which contains the records for all methods, and
    produces files in the directory "Databases". Each file in "Databases" is specialised for each
    method.
*)

theory Preprocess
  imports Pure
begin

ML{* signature PREPROCESS =
sig
  val preprocess: unit -> unit;
  val show_num_of_remaining_lines: bool;
  val parallel_preprocess: bool;
  val all_method_names   : string list;
  val print_all_meth_names: unit -> unit;
end;
*}

ML{* structure Preprocess : PREPROCESS =
struct

val show_num_of_remaining_lines = true;
val parallel_preprocess = true;

fun get_tokens (line:string) = line
  |> space_explode " "
  |> filter_out (fn x => x = " ")
  |> chop 1
  |> apfst the_single;

val path = Resources.master_directory @{theory} |> File.platform_path : string;
val path_to_database  = path ^ "/Database" : string;
val path_to_databases = path ^ "/Databases/" : string;

fun write_one_line_for_one_method (line:string) (method_name:string) =
  let
    val (file_name, features) = get_tokens line : (string * (string list));
    val meth_used    = if file_name = method_name then "1," else "0,";
    val feature_str  = String.concatWith "" (meth_used :: features) : string;
    val bash_command = "echo -n '" ^ feature_str ^ "\n' " ^ ">> " ^ path_to_databases ^ method_name;
    val exit_int     = Isabelle_System.bash (bash_command:string);
    val _ = if exit_int = 0 then () else tracing "write_one_line_for_one_method failed! The bach returned a non-0 value.";
  in
    ()
  end;

fun write_one_lines_for_given_methods (line:string) (method_names:string list) =
  map (write_one_line_for_one_method line) method_names;

val all_method_names =
  let
    val bash_script = "while read line \n do echo $line | awk '{print $1;}' \n done < '" ^ path_to_database ^ "'" : string;
    val bash_input  = Bash.process bash_script |> #out : string;
    val dist_meth_names = bash_input |> String.tokens (fn c => c = #"\n") |> distinct  (op =);
  in
    dist_meth_names : string list
  end;

fun print_one_meth_name (meth_name:string) =
  let
    val bash_command = "echo -n '" ^ meth_name  ^ "\n' " ^ ">> " ^ path ^ "/method_names";
    val exit_int = Isabelle_System.bash (bash_command:string);
    val _ = if exit_int = 0 then () else tracing "print_one_meth_name failed! The bach returned a non-0 value.";
  in () end;

fun print_all_meth_names _ =
  let
    val bash_command = "rm " ^ path ^ "/method_names";
    val exit_int = Isabelle_System.bash (bash_command:string);
    val _ = if exit_int = 0 then () else tracing "print_all_meth_names failed! The bach returned a non-0 value.";
    val _ = map print_one_meth_name all_method_names;
  in () end;

fun write_one_lines_for_all_methods (line:string) = write_one_lines_for_given_methods line all_method_names;

fun write_databases_for_given_lines_seq [] _ = []
 |  write_databases_for_given_lines_seq (line::lines:string list) _ =
 (if show_num_of_remaining_lines then (lines |> length |> Int.toString |> tracing) else ();
  write_one_lines_for_all_methods line :: write_databases_for_given_lines_seq lines ());

fun write_databases_for_given_lines_para (lines:string list) _ = Par_List.map write_one_lines_for_all_methods lines;

fun write_databases_for_all_lines _ =
  let
    val bash_script      = "while read line \n do echo $line \n done < '" ^ path_to_database ^ "'" : string;
    val bash_input       = Bash.process bash_script |> #out : string;
    val bash_input_lines = bash_input |> String.tokens (fn c => c = #"\n");
    val _                = Isabelle_System.bash ("rm -r " ^ path_to_databases ^ "*");
    val _                = Isabelle_System.bash ("mkdir " ^ path_to_databases);
    val result = if parallel_preprocess then
      write_databases_for_given_lines_para bash_input_lines () else
      write_databases_for_given_lines_seq  bash_input_lines ();
  in
    result
  end;

fun preprocess _ = (print_all_meth_names (); write_databases_for_all_lines (); ());

end;
*}

ML{* Preprocess.print_all_meth_names ()*}

ML{* Preprocess.preprocess  *}

end