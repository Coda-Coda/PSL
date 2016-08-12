(* This file, Example.thy, contains small examples, including Example2 presented in the FM2016 draft. *)
theory Example
imports PSL 
begin

strategy Hammer = Hammer
lemma "True \<or> False"
find_proof Hammer
oops

strategy Dff = Dynamic (Fastforce)
lemma "True"
find_proof Dff
oops

inductive foo::"'a \<Rightarrow> 'a \<Rightarrow> bool" where
  "foo x y"

(* You can use the default strategy with a single command "try_hard".*)
lemma "foo 8 90"
find_proof Hammer
apply -
oops

definition "my_true = True"
lemma my_truth: "my_true \<and> True"
try_hard
apply -
oops

lemma assumes D shows "B \<longrightarrow> B \<or> C" and "D" and "D"
try_hard
apply -
oops

strategy my_strategy = Thens [Skip, Alts [Fail, Ors [Fail, Hammer]]]

lemma
  assumes "B"
  shows "B \<and> (True \<or> False)"
find_proof my_strategy
apply -
oops

strategy Simps =  RepeatN ( Ors [Simp, Defer] )

lemma shows "True" and "False" and "True" and "True"
find_proof Simps
apply -
oops

(* By deferring non-sledgehammable proof obligations, human engineers can focus on meaningful
 * parts of their problems. *)
strategy Hammers =  RepeatN ( Ors [Hammer, Defer]  )

(* A radically simplified example. *)
definition "ps_clear (_::bool) (_::bool) \<equiv> True"
definition "valid_trans p s s' x \<equiv> True"

lemma cnjct2: 
shows 1:"ps_clear p s"
 and  2:"valid_trans p s s' x"
 and  3:"ps_clear p s'"
find_proof Hammers
apply -
oops

lemma "x \<or> True" and "(1::int) > 0"
try_hard
apply -
oops

end