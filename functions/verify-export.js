const functions = require("./index");

if (typeof functions.scoreChallengePhoto !== "function") {
  throw new Error("scoreChallengePhoto n'est pas exportée par functions/index.js");
}

console.log("scoreChallengePhoto est correctement exportée.");
