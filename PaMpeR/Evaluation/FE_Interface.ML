(*  Title:  FE_Interface.ML
    Author: Yilun He, Data61, CSIRO
            Yutaka Nagashima, CIIRC, CTU    

    Initiates the Feature Extraction system by overwritting Isar 
    keyword apply and by.
    
    Warning: Requires disabling the duplication check in outer_syntax.ML
    
    To generate Database, please do the following:

        1.Search and open outer_syntax.ML. (It usually resides in src/Pure/Isar/)
        2. a. Replace the return value of function err_dup_command by ()
           b. Re-define the "merge" function in the structure "Data" as following:
              fun merge data : T = data |> Symtab.join (fn name => fn (cmd1, cmd2) => cmd2);
        3.Search and open Main.thy
        4.import PaMpeR into Main
        5.add a ML chunk of function call ML{*FE_Interface.FE_activate ()*} in Main
        6.Rebuild Isabelle heap

    By default the extracted feature file would be stored in PSL/PaMpeR.
    If the import does not work, please add a function call of FE_Interface.activate ()
    in a ML chunk in Main.thy
*)

(*TODO: this file contains large volume of code duplication with PaMpeR/Build_Database/FE_Interface.ML*)
signature FE_INTERFACE = 
sig
  val FE_activate : unit -> unit
end;
structure FE_Interface : FE_INTERFACE = 
struct

  fun get_name (Method.Source src) = ((Token.name_of_src src)|>fst)
    | get_name _ = "\n"

  fun FE_activate _ = 
  let

    val path = Resources.master_directory @{theory} |> File.platform_path : string;
    val path_to_evaluation  = path ^ "/evaluation.txt" : string;
    
    val _ =
      Outer_Syntax.command @{command_keyword apply} "initial goal refinement step (unstructured)"
        (Method.parse >> (fn m => (Method.report m;
          Toplevel.proofs (fn pst =>(if (get_name o fst) m = "\n" then 0 else
          Isabelle_System.bash
            ("echo -n '" ^
             (PaMpeR_Interface.get_method_rank ((get_name o fst) m) pst) ^ "\n" ^
             "' >> " ^ path_to_evaluation);
          Proof.apply m pst)))));

    val local_terminal_proof = Toplevel.proof o 
          (fn m => 
            (fn state => 
              (if (get_name o fst) (fst m) = "\n" then 0 else
            Isabelle_System.bash 
              ("echo -n '" ^
               ((PaMpeR_Interface.get_method_rank ((get_name o fst o fst) m) state)) ^ "\n" ^
               "' >> " ^ path_to_evaluation);
            Proof.local_future_terminal_proof m state)));

    val global_terminal_proof = 
        Toplevel.end_proof o 
        K o 
        (fn m => 
            (fn state => (if (get_name o fst o fst) m = "\n" then 0 else
            Isabelle_System.bash
              ("echo -n '" ^
              (PaMpeR_Interface.get_method_rank ((get_name o fst o fst) m) state) ^ "\n" ^
               "' >> " ^ path_to_evaluation);
            Proof.global_future_terminal_proof m state)))
    
    fun terminal_proof m = local_terminal_proof m o global_terminal_proof m;
    
    val _ =
      Outer_Syntax.command @{command_keyword by} "terminal backward proof"
        (Method.parse -- Scan.option Method.parse >> (fn (m1, m2) =>
         (Method.report m1;
          Option.map Method.report m2;
          terminal_proof (m1, m2))));
  in
    ()
  end;
end;