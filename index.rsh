'reach 0.1';

const [ isHand, ZERO, ONE, TWO, THREE, FOUR, FIVE ] = makeEnum(6);
const [ isVocal, ZEROV, ONEV, TWOV, THREEV, FOURV, FIVEV, SIXV, SEVENV, EIGHTV, NINEV, TENV ] = makeEnum(11);
const [ isOutcome, B_WINS, DRAW, A_WINS ] = makeEnum(3);

const winner = (handAlice, handBob, vocalAlice, vocalBob) =>{

    if(vocalAlice == vocalBob)
    {
        const myoutcome = DRAW; //tie
        return myoutcome;
     } else {
      if ( ((handAlice + handBob) == vocalAlice ) ) {
        const myoutcome = A_WINS;
        return myoutcome;// player A wins
      }
        else {
          if (  ((handAlice + handBob) == vocalBob)) {
            const myoutcome = B_WINS;
            return myoutcome;// player B wins
        }
          else {
            const myoutcome = DRAW; // tie
            return myoutcome;
          }
     
        }
      }
     


};


forall(UInt, handAlice =>
    forall(UInt, handBob =>
      forall(UInt, vocalAlice =>
        forall(UInt, vocalBob =>
      assert(isOutcome(winner(handAlice, handBob, vocalAlice, vocalBob)))))));
   
   
   
   forall(UInt, (handAlice) =>
    forall(UInt, (handBob) =>      
      forall(UInt, (vocal) =>
        assert(winner(handAlice, handBob, vocal, vocal) == DRAW))));   
   

  const Player =
  { ...hasRandom,
    getHand: Fun([], UInt),
    getVocal: Fun([UInt], UInt),
    seeWinning: Fun([UInt], Null),
    seeOutcome: Fun([UInt], Null) ,
    informTimeout: Fun([], Null)
   };
export const main = Reach.App(() => {
  const Alice = Participant('Alice', {
    ...Player,
    wager: UInt, // atomic units of currency
    deadline: UInt, // time delta (blocks/rounds)
  });
  const Bob   = Participant('Bob', {
    ...Player,
    acceptWager: Fun([UInt], Null),
  });
  
  init();

  const informTimeout = () => {
    each([Alice, Bob], () => {
      interact.informTimeout();
    });
  };

  Alice.only(() => {
    const wager = declassify(interact.wager);
    const deadline = declassify(interact.deadline);
  });
  Alice.publish(wager, deadline)  //Alice is paying the wager and publishing a deadline
    .pay(wager);
  commit();

  Bob.only(() => {
    interact.acceptWager(wager); //Bob accepts wager
  });
  Bob.pay(wager)
    .timeout(relativeTime(deadline), () => closeTo(Alice, informTimeout)); //Timeout

  var outcome = DRAW;    //Outcome variable which is equals to DRAW 
  invariant( balance() == 2 * wager && isOutcome(outcome) ); //Condition which has to be truth and it is not changing before, in nor after loop
  while ( outcome == DRAW ) {   //While loop - Looping as long as variable outcome is equal DRAW
    commit(); //Moving from consensus to local step

    Alice.only(() => {      
      const _handAlice = interact.getHand();  //What Alice showed
      const _vocalAlice = interact.getVocal(_handAlice);
      const [_commitAlice, _saltAlice] = makeCommitment(interact, _handAlice); //Unique relationship between value and commitment
      const commitAlice = declassify(_commitAlice); //What Alice showed is still hidden, only the commitment is revealed
      const [_vocalCommitAlice, _vocalSaltAlice] = makeCommitment(interact, _vocalAlice);
      const vocalCommitAlice = declassify(_vocalCommitAlice);  

    }); 
    Alice.publish(commitAlice)
      .timeout(relativeTime(deadline), () => closeTo(Bob, informTimeout)); //Timeout if Bob is not responding
    commit();
    Alice.publish(vocalCommitAlice)
    .timeout(relativeTime(deadline), () => closeTo(Bob, informTimeout));
    ;
  commit();


    unknowable(Bob, Alice(_handAlice, _saltAlice)); //Now we know that Bob can't know what private value Alice showed
    unknowable(Bob, Alice(_handAlice, _vocalSaltAlice));
    Bob.only(() => {
        const _handBob = interact.getHand();
        const _vocalBob = interact.getVocal(_handBob);
        const handBob = declassify(_handBob);
        const vocalBob = declassify(_vocalBob); 


    });
    Bob.publish(handBob) //Bob is publishing what he showed
      .timeout(relativeTime(deadline), () => closeTo(Alice, informTimeout)); //Timeout
    commit();

    Bob.publish(vocalBob)
    .timeout(relativeTime(deadline), () => closeTo(Alice, informTimeout));
    ;

  commit();


    Alice.only(() => {    //Now we can reveal Alices values
      const saltAlice = declassify(_saltAlice); 
      const handAlice = declassify(_handAlice);
      const [vocalSaltAlice, vocalAlice] = declassify([_vocalSaltAlice, _vocalAlice]);

    });
    Alice.publish(saltAlice, handAlice)   //Alice is publishing info so we can use them
      .timeout(relativeTime(deadline), () => closeTo(Bob, informTimeout)); //Timeout (if she is not responding)
    checkCommitment(commitAlice, saltAlice, handAlice); //Checking if Alice tried to change what she showed at the begining

    commit();

    Alice.publish(vocalSaltAlice, vocalAlice)
    .timeout(relativeTime(deadline), () => closeTo(Bob, informTimeout));
    checkCommitment(vocalCommitAlice, vocalSaltAlice, vocalAlice);

    commit();

    Alice.only(() => {       
        const WinningNumber = handAlice + handBob;
        interact.seeWinning(WinningNumber);
      });

      Alice.publish(WinningNumber).timeout(relativeTime(deadline), () => closeTo(Alice, informTimeout));


    outcome = winner(handAlice, handBob,vocalAlice, vocalBob);   //Updating value of loop variable outcome (we are sending values to function Winner, which returns outcome)
    continue;   //Reach requires continue for WHILE loops (returning to loop condition)
  }   //End of loop

  assert(outcome == A_WINS || outcome == B_WINS);   //Checking if outcome is Alice won or Bob won
  transfer(2 * wager).to(outcome == A_WINS ? Alice : Bob);  //Transfer of a wager to the winner
  commit(); //Exit consensus

  each([Alice, Bob], () => {
    interact.seeOutcome(outcome); //Showing outcome for each
  });
});