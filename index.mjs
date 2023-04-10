import { loadStdlib, ask } from '@reach-sh/stdlib';
import * as backend from './build/index.main.mjs';
const stdlib = loadStdlib();

const isAlice = await ask.ask(
  `Are you Alice?`,
  ask.yesno
);
const who = isAlice ? 'Alice' : 'Bob';
console.log(`Launching game as ${who}`);

let acc = null;
const createAcc = await ask.ask(
  `Would you like to create an account?`,
  ask.yesno 
);

if (createAcc) {
  acc = await stdlib.newTestAccount(stdlib.parseCurrency(1000));
} else {
  const secret = await ask.ask(`What is your account secret?`, (x => x));
  acc = await stdlib.newAccountFromSecret(secret);
}
let ctc = null;

if (isAlice) {
  ctc = acc.contract(backend);
  ctc.getInfo().then((info) => {
    console.log(`The contract is deployed as = ${JSON.stringify(info)}`);
  });
} else {
  const info = await ask.ask(
    `Please paste the contract information:`,
    JSON.parse
  );
  ctc = acc.contract(backend, info);
}




const fmt = (x) => stdlib.formatCurrency(x, 4);
const getBalance = async (who) => fmt(await stdlib.balanceOf(acc));
const before = await getBalance();
console.log(`Your balance is ${before}`);



const HAND = [0, 1, 2, 3, 4, 5];
const VOCAL = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
const OUTCOME = ['Bob wins', 'Draw', 'Alice wins'];
const interact = { ...stdlib.hasRandom };


  interact.getHand = async () => { // <-- async now
    const hand = await ask.ask(`How many fingers do you raise (1-5)`, (x) => {
      const hand = HAND[x];
      if ( hand === undefined || hand==0 ) {
       throw Error('Invalid input');
      }
     return hand;
   });
   console.log(`You raised ${HAND[hand]} fingers`);
   return hand;
 };
 


 

    interact.getVocal = async () => {
      const vocal = await ask.ask(`Say how many fingers you think are raised (2-10)?`, (x) => {
        const vocal= VOCAL[x];
         if ( vocal === undefined || vocal==0 || vocal==1 ) {
          throw Error(`Invalid input`);
         }
        return vocal;
      });
      console.log(`You guessed ${VOCAL[vocal]} fingers`);
      return vocal;
    }; 

    
    
  
   interact.seeWinning = (winningNumber) => {   
    console.log(`Actual total fingers raised: ${winningNumber}`);
  };



  

  
  interact.seeOutcome = async (outcome) => {
    console.log(`${who} saw outcome ${OUTCOME[outcome]}`);
  };
  interact.informTimeout = () => {
    console.log(`${who} observed a timeout`);
    process.exit(1);
  };

if (isAlice) {

  const amt = await ask.ask(
    'Enter the amount to wager',
    stdlib.parseCurrency
    );
    interact.wager = amt;
  interact.deadline = { ETH: 100, ALGO: 100, CFX: 1000 }[stdlib.connector];
} else {
  interact.acceptWager = async (amt) => {
    const accepted = await ask.ask(
      `Do you accept the wager amount of: ${fmt(amt)}?`,
      ask.yesno
    );
    if (!accepted) {
      process.exit(0);
    }
  };
}
  
const part = isAlice ? ctc.p.Alice : ctc.p.Bob;
await part(interact);

const after = await getBalance();
console.log(`Your balance is now: ${after}`);

ask.done();


