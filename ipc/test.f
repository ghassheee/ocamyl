A->A ;
Top /\ Top -> Top;

A /\ (B \/ C)-> (A /\ B ) \/ C ;

P -> (( P -> Bot) -> Bot)  ;

(((( P -> Bot )  -> Bot) -> P) -> Bot) -> Bot  ;

A /\ (A -> B) -> B ; 

(~A) -> (~A) ;

(~P -> P) /\ (P -> ~P) -> Q /\ ~Q;

(P -> Q) \/ (P -> R) -> P -> Q \/ R ; 

A -> B -> B ; 

~A /\ ~B -> ~(A \/ B); 

~(A \/ B) -> ~A /\ ~B ; 

A -> B -> A ;

A -> ~(~A) ;

~A \/ ~B -> ~(A/\B) ;


~(~(P \/ ~P)) ; 

(A/\A -> A) -> (A -> A);


~(~(~A)) -> ~A ; 

