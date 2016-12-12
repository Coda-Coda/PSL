(* This file, Example.thy, contains small examples, including Example3 presented in the TACAS2017 draft. *)
theory Example
imports PSL "~~/src/HOL/Eisbach/Eisbach"
begin

(* The "Hammer" strategy invokes sledgehammer as a sub-tool. *)
strategy Hammer = Hammer
lemma "True \<or> False"
find_proof Hammer
oops

(* The "POrs" and "PAlts" combinators exploit parallelism.*)
strategy Test_POrs = POrs [Fastforce, Hammer]
lemma
 assumes "P" shows "P"
find_proof Test_POrs
oops
strategy Test_PAlts = Thens [PAlts [Fastforce, Hammer], IsSolved]
lemma
 assumes "P" shows "P"
find_proof Test_PAlts
oops

(* The "User < >" syntax allows PSL to employ proof-methods defined by users via Eisbach inside
 * a proof strategy. *)
method my_simp = simp
strategy UserSimp = User <my_simp>
lemma "True \<and> True \<or> False"
find_proof UserSimp
oops

(* By combining Eisbach and "User < >", we can use Eisbach methods as conditions to apply strategies.*)
method if_match = (match conclusion in "((P::'a \<Rightarrow> 'b) = (Q::'a \<Rightarrow> 'b))" for P Q \<Rightarrow> \<open>succeed\<close>)
strategy IfMatchRuleExt = Thens [User <if_match>, User <rule ext>]
consts "QQ"::"'a \<Rightarrow> 'b"
consts "PP"::"'a \<Rightarrow> 'b"
lemma "QQ = PP"
find_proof IfMatchRuleExt
oops

(* One can also call the default proof methods via the "User" strategy. *)
definition "my_foo \<equiv> True"
strategy UserSimp2 = Thens [User < simp add: my_foo_def(1) >, IsSolved]
lemma "my_foo"
find_proof UserSimp2
oops

(* When having meta-quantified variables, "CaseTac" tends to be more useful than "Cases".*)
strategy CaseTac = Thens [Dynamic (CaseTac), Auto]
lemma "\<And>xs .((case xs of [] \<Rightarrow> [] | y#ys \<Rightarrow> xs) = xs)"
find_proof CaseTac
oops

(* The "IsSolved" strategy creates the "done" Isar-command upon success. *)
strategy MultiFF = Thens [Fastforce, IsSolved, Fastforce, IsSolved]
lemma "True" and "True"
apply -
subgoal
find_proof MultiFF
oops

(* The "Subgoal" strategy narrow the scope to the first sub-goal. *)
strategy Auto2 = Thens [Subgoal, Auto, IsSolved, Subgoal, Auto, IsSolved]
lemma "True" and "True"
find_proof Auto2
oops

(* Users can employ the default strategy with a single command "try_hard".*)
inductive foo::"'a \<Rightarrow> 'a \<Rightarrow> bool" where
  "foo x y"
lemma "foo 8 90"
find_proof Hammer
try_hard
oops
lemma assumes D shows "B \<longrightarrow> B \<or> C" and "D" and "D"
try_hard
oops

(* The "Skip" strategy always succeeds, while the "Fail" strategy always returns an empty sequence. *)
strategy my_strategy = Thens [Skip, Alts [Fail, Ors [Fail, Hammer]]]
lemma
  assumes "B"
  shows "B \<and> (True \<or> False)"
find_proof my_strategy
oops

(* The "Defer" combinator send the first sub-goal to the end of the list of sub-goals.*)
(* By deferring difficult sub-goals using the "Defer" combinator while discharging easy ones
 * automatically, human engineers can focus on meaningful parts of their problems. *)
strategy Simps =  RepeatN ( Ors [Simp, Defer] )
lemma shows "True" and "False" and "True" and "True"
find_proof Simps
oops

(* By combining "Defer" and "Hammer", we can discharge some proof obligations automatically with
 * sledgehammer, while focusing on "difficult" problems.  *)
strategy Hammers =  RepeatN ( Ors [Hammer, Defer]  )
definition "safe_state x y \<equiv> True"
lemma state_safety:"safe_state (x::bool) (y::bool) = True"
apply normalization done

definition "ps_safe (x::bool) (y::bool) \<equiv> safe_state True True"
definition "valid_trans p s s' x \<equiv> True"

lemma cnjct2:
shows 1:"ps_safe p s"
 and  2:"valid_trans p s s' x"
 and  3:"ps_safe p s'"
find_proof Hammers
oops

(* The "Cut" combinator restricts non-determinism by pruning branches. *)
strategy testCut = Thens [Repeat (Cut 10 (Dynamic (Rule))), IsSolved]
lemma "True \<and> True"
find_proof testCut
oops

end