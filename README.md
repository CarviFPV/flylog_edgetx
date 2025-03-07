# FlyLog - A Simple Logging Script for EdgeTX

This script logs the arming and disarming events of your model, along with date/time, GPS coordinates, and the model name. It is intended for use on EdgeTX-based transmitters.

## Features

- Logs arming and disarming events
- Records date, time, GPS coordinates, and model name
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

- **Arming**: When you toggle your chosen switch from the disarmed state to the armed state, the script will log the "Arming" event, along with the current date/time, and the GPS coordinates at arming.
- **Disarming**: When you toggle the switch back to disarmed, the script logs the "Disarming" event, along with the disarming date/time, GPS coordinates, and the total duration (in seconds) of the armed flight.

After each flight, a new line will be added to the `flylog.csv` file in your transmitter’s `LOGS` folder.

## Log File Format

The CSV file (`flylog.csv`) now contains the following columns:

Arming,Date,Timestamp-TO,GPS-Arming-Lat,GPS-Arming-Lon,Disarming,Timestamp-LDG,GPS-Disarming-Lat,GPS-Disarming-Lon,Duration,ModelName

Each row corresponds to a single flight:
- **Arming**: A constant text field ("Arming").
- **Date**: The flight date in `YYYY-MM-DD` format.
- **Timestamp-TO**: The arming time (takeoff) in `HH:MM:SS` format.
- **GPS-Arming-Lat**: Latitude at the moment of arming (currently set to `0.000000`).
- **GPS-Arming-Lon**: Longitude at the moment of arming (currently set to `0.000000`).
- **Disarming**: A constant text field ("Disarming").
- **Timestamp-LDG**: The disarming time (landing) in `HH:MM:SS` format.
- **GPS-Disarming-Lat**: Latitude at the moment of disarming (currently set to `0.000000`).
- **GPS-Disarming-Lon**: Longitude at the moment of disarming (currently set to `0.000000`).
- **Duration**: The flight duration in seconds.
- **ModelName**: The name of the model used during the flight.

*Note:* The GPS coordinate fields are placeholders (set to zero) in this example. They can be updated to include real-time GPS data if available.

## License

This project is licensed under the **MIT License**.

## Notes

- The script automatically creates the `flylog.csv` file if it does not exist.
- Ensure that your radio has logging enabled and sufficient storage for logs.
- The script uses `getDateTime()` to log accurate timestamps.
