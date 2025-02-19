# FlyLog - A Simple Logging Script for EdgeTX

This script logs the arming and disarming events of your model, along with date/time and the model name. It is intended for use on EdgeTX-based transmitters.

## Features

- Logs arming and disarming events
- Records date, time, and model name
- Creates a CSV log file (`/LOGS/flylog.csv`) if it doesn't exist
- Easy setup using the EdgeTX "Special Functions" menu

## Installation

1. **Download/Obtain the Script**  
   Save the `flylog.lua` file into the `SCRIPTS/FUNCTIONS` directory on your EdgeTX SD card.

2. **Configure the Script in EdgeTX**  
   1. On your EdgeTX transmitter, open the **Model** page and navigate to the **Special Functions** tab.
   2. Create a new special function (tap the `+` icon).
   3. Under **Trigger**, select the switch you want to use to start/stop logging (e.g., your arming switch).
   4. Under **Function**, choose **Lua Script**.
   5. Under **Value**, select `flylog.lua`.
   6. Set **Repeat** to **ON**.
   7. Make sure **Enable** is toggled on.

   Refer to the provided screenshots for an example of how this is set up.

## Usage

- **Arming**: When you toggle your chosen switch from the disarmed state to the armed state, the script will log the "Arming" event, along with the current date/time and model name.
- **Disarming**: When you toggle the switch back to disarmed, the script logs the "Disarming" event, along with the date/time of disarming and the total duration (in seconds) of the armed flight.

After each flight, a new line will be added to the `flylog.csv` file in your transmitter’s `LOGS` folder.

## Log File Format

The CSV file (`flylog.csv`) contains the following columns:

Arming,Date,Timestamp-TO,Disarming,Timestamp-LDG,Duration,ModelName
Arming,2025-02-19,19:00:00,Disarming,19:15:30,15.50,MyDrone

Each row corresponds to a single flight.  
- **Arming**: Will always be "Arming"  
- **Date**: YYYY-MM-DD format  
- **Timestamp-TO**: Time of arming in HH:MM:SS format  
- **Disarming**: Will always be "Disarming"  
- **Timestamp-LDG**: Time of disarming in HH:MM:SS format  
- **Duration**: The flight duration in seconds  
- **ModelName**: The name of the model in use during the flight  

## License
This project is licensed under the **MIT License**.

## Notes
- The script automatically creates the `flylog.csv` file if it does not exist.
- Ensure that your radio has logging enabled and sufficient storage for logs.
- The script uses `getDateTime()` to log accurate timestamps.
