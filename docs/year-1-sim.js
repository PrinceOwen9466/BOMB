const DECIMALS = 5;
const INITIAL_SUPPLY = 325 * 10 ** 3 * 10 ** DECIMALS;
const MAX_SUPPLY = 325 * 10 ** 7 * 10 ** DECIMALS;
const REBASE_RATE = 1915;
const REBASE_INTERVAL = 900; // 15 mins
const REBASE_COUNT_PER_YEAR = 35064; // 31557600 / 900 => 1 year / 15 mins

const RATE_DECIMALS = 7;
const DECIMAL_CONST = 10 ** RATE_DECIMALS;

let supply = INITIAL_SUPPLY;
let time = 0;
let line = ""; let szTime = ""
let output = "";

output += "$BOMB rebase simulation\n-------------------------------\n\n";
output += `Inital Supply: ${supply}\n`;
output += `Max Supply: ${MAX_SUPPLY}\n\n`;


for (let i = 0; i < REBASE_COUNT_PER_YEAR; i++) {  
  supply = (supply * (DECIMAL_CONST + REBASE_RATE)) / DECIMAL_CONST;
  supply = Math.floor(supply)
  
  time += REBASE_INTERVAL;
  szTime = seconds2time(time)
  
  
  
  line = `${supply} after ${szTime}`;
  
  output += line;
  output += "\n";
}

console.log(output);


function seconds2time (secs) {
		var days 		= Math.floor(secs / 86400);
		secs %= 86400;

    var hours   = Math.floor(secs / 3600);
    var minutes = Math.floor((secs - (hours * 3600)) / 60);
    var seconds = secs - (hours * 3600) - (minutes * 60);
    var time = "";

		return `${days > 0 ? days + ' days ': ''}${hours > 0 ? hours + ' hours ': ''}${minutes > 0 ? minutes + ' minutes ': ''}${seconds > 0 ? seconds + ' seconds': ''}`.trim();
}