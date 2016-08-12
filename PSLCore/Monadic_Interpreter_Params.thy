(* This file fleshes out this skeleton with concrete evaluation functions. *)
theory Monadic_Interpreter_Params
imports
  "../Runtime/Dynamic_Simp"
  "../Runtime/Dynamic_Induct"
  "../Runtime/Dynamic_Rule"
  "../Runtime/Dynamic_ERule"
  "../Runtime/Dynamic_Sledgehammer"
  "../Runtime/Dynamic_Classical"
  "../Utils/Quickcheck_as_Tactic"
  "../Utils/Nitpick_as_Tactic"
  Monadic_Interpreter
begin

text{* concrete monadic prover *}

ML{* signature MONADIC_INTERPRETER_PARAMS =
sig
  type eval_prim;
  type eval_para;
  type eval_tactical;
  type m_equal;
  type iddfc;
  val eval_prim    : eval_prim;
  val eval_para    : eval_para;
  val eval_tactical: eval_tactical;
  val m_equal      : m_equal;
  val iddfc        : iddfc;
end;
*}

ML{* structure Monadic_Interpreter_Param : MONADIC_INTERPRETER_PARAMS =
struct

  open Monadic_Interpreter;
  type state           = Proof.state;
  type 'a seq          = 'a Seq.seq;
  type ctxt            = Proof.context;
  type thms            = thm list;
  type strings         = string list;
  type eval_prim       = prim_tac -> state stttac;
  type eval_para       = para_tac -> state -> state stttac Seq.seq;
  type eval_tactical   = atom_tactical * state stttac list -> state stttac;
  type m_equal         = state monad -> state monad -> bool;
  type iddfc           = int -> (atom_tac -> state stttac) -> (atom_tac -> state stttac);
  (* For eval_prim. *)
  val quickcheck_tac   = Quickcheck_Tactic.nontac;
  val nitpick_tac      = Nitpick_Tactic.nontac;
  val string_to_stttac = Dynamic_Utils.string_to_stttac_on_pstate;
  val is_solved        = Tactic.is_solved;
  type log             = Dynamic_Utils.log;

  (* do_trace and show_trace are for debugging only. *)
  val do_trace = false;
  fun show_trace text = if do_trace then tracing text else ();

  (* I cannot move the definition of "eval_prim" into mk_Monadic_Interpreter,
   * because its type signature is too specific.*)
  fun eval_prim (prim:prim_tac) (goal_state:state) =
    let
      val defer_meth_name        = "tactic {* defer_tac 1 *" ^"}";
      val defer_stttac           = Seq.single o (Proof.defer 1);
      val log_n_nontac_to_stttac = Dynamic_Utils.log_n_nontac_to_stttac;
      val tac_on_proof_state : state stttac =
       case prim of
        CClarsimp =>  (show_trace "CClarsimp";  string_to_stttac "HOL.clarsimp")
      | CSimp =>      (show_trace "CSimp";      string_to_stttac "HOL.simp")
      | CFastforce => (show_trace "CFastforce"; string_to_stttac "HOL.fastforce")
      | CAuto =>      (show_trace "CAuto";      string_to_stttac "HOL.auto")
      | CInduct =>    (show_trace "CInduct";    string_to_stttac "HOL.induct")
      | CCase   =>    (show_trace "CCase";      string_to_stttac "HOL.cases")
      | CRule   =>    (show_trace "CRule";      string_to_stttac "HOL.rule")
      | CErule  =>    (show_trace "CErule";     string_to_stttac "HOL.erule")
      | CHammer =>    (show_trace "CHammer";    Dynamic_Sledgehammer.pstate_stttacs)
      (* assertion tactics *)
      | CIs_Solved => (show_trace "CIs_Solved"; log_n_nontac_to_stttac ([], is_solved))
      | CQuickcheck=> (show_trace "CQuickcheck";log_n_nontac_to_stttac ([], quickcheck_tac))
      | CNitpick   => (show_trace "CNitpick";   log_n_nontac_to_stttac ([], nitpick_tac))
      | CDefer     => (show_trace "CDefer";
          log_n_nontac_to_stttac ([{methN = defer_meth_name, using = [], back = 0}], defer_stttac))
    in
       tac_on_proof_state goal_state : state monad
    end;

  fun eval_para (tac:para_tac) (state:Proof.state) =
    let
      type 'a stttac = 'a Dynamic_Utils.stttac;
      val get_state_stttacs = case tac of
          CPara_Simp =>      (show_trace "CPara_Simp";      Dynamic_Simp.get_state_stttacs)
        | CPara_Induct =>    (show_trace "CPara_Induct";    Dynamic_Induct.get_state_stttacs)
        | CPara_Rule =>      (show_trace "CPara_Rule";      Dynamic_Rule.get_state_stttacs)
        | CPara_Erule =>     (show_trace "CPara_Erule";     Dynamic_Erule.get_state_stttacs)
        | CPara_Fastforce => (show_trace "CPara_Fastforce"; Dynamic_Fastforce.get_state_stttacs)
        | CPara_Clarsimp =>  (show_trace "CPara_Clarsimp";  Dynamic_Clarsimp.get_state_stttacs)
    in
      (* It is okay to use the type list internally,
       * as long as the overall monadic interpretation framework is instantiated to Seq.seq for 
       * monad with 0 and plus.*)
      get_state_stttacs state : state stttac Seq.seq
    end;

  fun m_equal (st_mona1:state monad) (st_mona2:state monad) =
  (* Probably, I do not have to check the entire sequence in most cases.
   * As the length of sequences can be infinite in general, I prefer to test a subset of these.*)
    let
      type lstt   = Log_Min.monoid_min * state;
      type lstts  = lstt seq;
      fun are_same_one (x : lstt,  y : lstt)  = apply2 (#goal o Proof.goal o snd) (x, y)
                                             |> Thm.eq_thm;
      fun are_same_seq (xs: lstts, ys: lstts) = Seq2.same_seq are_same_one (xs, ys) ;
      val xs_5 : lstts                        = st_mona1 [] |> Seq.take 5;
      val ys_5 : lstts                        = st_mona2 [] |> Seq.take 5;
    in
      are_same_seq (xs_5, ys_5)
    end;

  fun solve_1st_subg (tac : state stttac) (goal:state) (_:log) =
    let
      val get_thm = Isabelle_Utils.proof_state_to_thm;
      fun same_except_for_fst_prem' x y = Tactic.same_except_for_fst_prem (get_thm x) (get_thm y)
    in
      tac goal [] |> Seq.filter (fn (_, st')  => same_except_for_fst_prem' goal st') : (log * state) Seq.seq
    end;

  fun repeat_n (tac : state stttac) (goal : state) = (fn (_:log) =>
    let
      fun repeat_n' (0:int) (g:state) = return g
       |  repeat_n' (n:int) (g:state) = if n < 0 then error "" else
            bind (tac g) (repeat_n' (n - 1));
      val subgoal_num = Isabelle_Utils.proof_state_to_thm goal |> Thm.nprems_of;
    in
      (* We have to add 1 because of Isabelle's strange evaluation (parse-twice thingy).*)
      repeat_n' subgoal_num goal [] : (log * state) Seq.seq
    end) : state monad;

  fun eval_tactical (CSolve1, [tac : state stttac])  = solve_1st_subg tac
   |  eval_tactical (CSolve1, _)  = error "eval_tactical failed. M.Solve1 needs exactly one tactic."
   |  eval_tactical (CRepeatN, [tac : state stttac]) = repeat_n tac
   |  eval_tactical (CRepeatN, _) = error "eval_tactical failed. M.RepeatN needs exactly one tactic."

  fun iddfc (limit:int)
    (smt_eval:'atom_tac -> 'state stttac) (atac:'atom_tac) (goal:'state) (trace:log) =
    let
      val wmt_eval_results = smt_eval atac goal trace |> Seq.pull;
      val trace_leng = wmt_eval_results |> Option.map fst |> Option.map fst |> Option.map length;
      infix is_maybe_less_than
      fun (NONE is_maybe_less_than   (_:int)) = false
       |  (SOME x is_maybe_less_than (y:int)) = x < y;
      val smt_eval_results = if is_none trace_leng orelse trace_leng is_maybe_less_than limit
                            then Seq.make (fn () => wmt_eval_results) else Seq.empty;
    in
      smt_eval_results
    end;

end;
*}

ML{* signature MONADIC_PROVER =
sig
 include MONADIC_INTERPRETER;
 include MONADIC_INTERPRETER_PARAMS;
end;
*}

end