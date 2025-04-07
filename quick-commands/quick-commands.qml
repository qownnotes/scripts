import QtQml 2.0
import QOwnNotesTypes 1.0

/**
 * This script creates some easy to access commands that leverage the autocomplete functionalities to add more predefined
 * strings or formatted dates
 *
 */

Script {
    // DateFormats
    readonly property string _YYYYMMDD : "YYYY-MM-DD";
    readonly property string _DDMMYYYY : "DD-MM-YYYY";
    readonly property string _DDMM : "DD-MM";
    readonly property string _WWYYYY : "WW-YYYY";
    readonly property string _WEEKWWYYYY : "wWW-YYYY";
    readonly property string _FULL : "YYYY-MM-DDTHH:mm:ss";

    readonly property int _MILLI_DAY : 86400000;
    property var commands;
    property string customCommands;

    property variant settingsVariables: [
        {
            "identifier": "customCommands",
            "name": "Custom Commands",
            "description": "Custom quick commands. Each line is a separate command, with the options split by space and the first word being the command name. For example: 'myName first first-last last-first'",
            "type": "text",
            "default": "",
        }
    ]   

    function init() {
        commands = new Object();
        reInitCommands();
    }

    function buildTimeList(date) {
        var timeList = [];
        timeList.push(formatDate(date, _DDMM));
        timeList.push(formatDate(date, _YYYYMMDD));
        timeList.push(formatDate(date, _DDMMYYYY));
        timeList.push(formatDate(date, _FULL));
        return timeList;
    }

    function reInitCommands(){
        var today = new Date();
        var todayMillis = today.getTime();
        var yesterday = new Date(todayMillis - _MILLI_DAY);
        var tomorrow = new Date(todayMillis + _MILLI_DAY);

        commands["today"] = buildTimeList(today);
        commands["tomorrow"] = buildTimeList(tomorrow);
        commands["yesterday"] = buildTimeList(yesterday);
        commands["week"] = [formatDate(today, _WWYYYY), formatDate(today, _WEEKWWYYYY)];
        commands["now"] = [formatDate(today, _FULL)];


        var customRows = customCommands.split("\n");
        for (let i = 0; i < customRows.length; i++) {
          var customCommandDetails = customRows[i].split(" ");
          var customCommandName = customCommandDetails[0];
          var customCommandValues = [];
          for (let j = 1; j < customCommandDetails.length; j++) {
            customCommandValues.push(customCommandDetails[j]);
          }

          commands[customCommandName] = customCommandValues;
        }
    }

    function autocompletionHook() {
        var word = script.noteTextEditCurrentWord(true);

        if (!word.startsWith("\\")) {
            return [];
        }

        // Have to re-init since reloading the script engine/restarting might not happen daily
        reInitCommands();

        var command = word.substr(1);

        var availableCommands = commands[command];
        if (availableCommands == null){
            return [];
        }

        return availableCommands;

    }

    // Taken from https://github.com/qownnotes/scripts/blob/master/journal-entry/journal-entry.qml
    function getWeekNumber(d) {
        // Copy date so don't modify original
        d = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
        d.setUTCDate(d.getUTCDate() + 4 - (d.getUTCDay()||7));
        var yearStart = new Date(Date.UTC(d.getUTCFullYear(),0,1));
        var weekNo = Math.ceil(( ( (d - yearStart) / 86400000) + 1)/7);
        return weekNo;
    }

    // Taken from https://github.com/qownnotes/scripts/blob/master/journal-entry/journal-entry.qml
    function formatDate(date, format) {
        let day = date.getDate();
        let month = date.getMonth() + 1; //getMonth() returns 0-11 so we must add 1
        let week = getWeekNumber(date);
        let year = date.getFullYear();
        let hours = date.getHours();
        let minutes = date.getMinutes();
        let seconds = date.getSeconds();

        // If day and month are less than 10, add a leading zero
        day = (day < 10) ? '0' + day : day;
        month = (month < 10) ? '0' + month : month;
        week = (week < 10) ? '0' + week : week;
        hours = (hours < 10) ? '0' + hours : hours;
        minutes = (minutes < 10) ? '0' + minutes : minutes;
        seconds = (seconds < 10) ? '0' + seconds : seconds;

        // Replace format placeholders by actual values
        format = format.replace('WW', week);
        format = format.replace('MM', month);
        format = format.replace('DD', day);
        format = format.replace('YYYY', year);
        format = format.replace('HH', hours);
        format = format.replace('mm', minutes);
        format = format.replace('ss', seconds);

        return format;
    }
}
