import { loadStdlib } from '@reach-sh/stdlib';
import * as backend from './build/index.main.mjs';
const stdlib = loadStdlib(process.env);

const startingBalance = stdlib.parseCurrency(100);
const accAlice = await stdlib.newTestAccount(startingBalance);
const accBob = await stdlib.newTestAccount(startingBalance);

const fmt = (x) => stdlib.formatCurrency(x, 4);
const getBalance = async (who) => fmt(await stdlib.balanceOf(who));
const beforeAlice = await getBalance(accAlice);
const beforeBob = await getBalance(accBob);

const ctcAlice = accAlice.contract(backend);
const ctcBob = accBob.contract(backend, ctcAlice.getInfo());

const HAND = [0, 1, 2, 3, 4, 5];
const VOCAL = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
const OUTCOME = ['Bob wins', 'Draw', 'Alice wins'];
const Player = (Who) => ({
  ...stdlib.hasRandom,
  getHand: async () => { // <-- async now
    const hand = Math.floor(Math.random() * 6);
    console.log(`${Who} raised ${HAND[hand]} fingers`);

    if ( Math.random() <= 0.01 ) {
      for ( let i = 0; i < 10; i++ ) {
        console.log(`  ${Who} takes their sweet time sending it back...`);
        await stdlib.wait(1);
      }
    }
    return hand;
  },
  getVocal:  async (hand) => {
    // vocal should be greater than or equal to number of fingers thrown
     const vocal= Math.floor(Math.random() * 6) + HAND[hand];
    // occasional timeout
     if ( Math.random() <= 0.01 ) {
       for ( let i = 0; i < 10; i++ ) {
         console.log(`  ${Who} takes their sweet time sending it back...`);
         await stdlib.wait(1);
       }
     }
     console.log(`${Who} guessed total of ${vocal}`);  
     return vocal;
   },
   seeWinning: (winningNumber) => {   
    console.log(`Actual total fingers raised: ${winningNumber}`);
  },




  
  seeOutcome: (outcome) => {
    console.log(`${Who} saw outcome ${OUTCOME[outcome]}`);
  },
  informTimeout: () => {
    console.log(`${Who} observed a timeout`);
  },
});

await Promise.all([
  ctcAlice.p.Alice({
    ...Player('Alice'),
    wager: stdlib.parseCurrency(5),
    deadline: 10,
  }),
  ctcBob.p.Bob({
    ...Player('Bob'),
    acceptWager: (amt) => {
      console.log(`Bob accepts the wager of ${fmt(amt)}.`); //Bob accepts wager
    },
  }),
]);

const afterAlice = await getBalance(accAlice);
const afterBob = await getBalance(accBob);

console.log(`Alice went from ${beforeAlice} to ${afterAlice}.`);
console.log(`Bob went from ${beforeBob} to ${afterBob}.`);

