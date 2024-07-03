
# Description : 

This project is used during the interview process to assess the candidate's level in Dart. 
The program run a Command Line Interface (CLI) to manage user input and operates a separate isolate to run an HTTP server that responds to various requests.
The server is included in the source code under `lib/server.dart`, and the project skeleton is provided.


A list of protocols (saved in a JSON file) contains a certain number of trials. After loading the JSON data, the user should be able to run a protocol by making a POST request. This POST request sets the protocol on the server side. 
Once the user subscribes to the '/result_event' route, data is sent as a Server-Sent Event. The server will yield a result for every trial of the loaded protocol. For example, if the POST has 4 trials, the 'result_event' will send 4 messages, one for each trial result. The result_event route send event with a delay and trials are not returning in the sequencial order to mock the async delay to compute the result. 

Here the example of the command line flow :

```
>> Enter your command :
> load /assets/protocols.json
CLI - Loading ok 

>> Enter your command :
> run_protocol Anti
>> How many trial do you want ? (Recommanded 10)
> 3
>> What is the color of target ?  (Recommanded red)
> red
CLI - Command sent to the server
Server : 2023-09-11 16:17:58.290460 - POST /run_protocol 200
Server : Protocol Anti will be played for 3 trials with a color red

>> Enter your command :
> results
Server : 2023-09-11 17:10:21.141672 - POST /result_event 200
log - Received data: {trial: 2, param: {color: yellow}, Result: {Latency_left_ms: 10, Latency_right_ms: 29}}
log - Received data: {trial: 0, param: {color: yellow}, Result: {Latency_left_ms: 0, Latency_right_ms: 63}}
log - Received data: {trial: 1, param: {color: yellow}, Result: {Latency_left_ms: 91, Latency_right_ms: 83}}

CLI - Result saved.

CLI - Result are : 
    0.{Latency_left_ms: 10, Latency_right_ms: 29}
    1.{Latency_left_ms: 0, Latency_right_ms: 63}
    2.{Latency_left_ms: 91, Latency_right_ms: 83}

>> Enter your command :
> all_results
CLI - Results :
    17:31 - Pro - average {Latency_left_ms : 15, Latency_right_ms : 60} 
    17:32 - Anti - average {Latency_left_ms : 40.3, Latency_right_ms : 58.3} 

```


## Project struture : 
- `/lib/interview_dart.dart` : Contains the main code that the candidate should modify.
- `/lib/server.dart` : Contains the provided server to handle HTTP responses. The candidate should not modify it, but can add some log if needed. 
- `/assets/protocols.json` : Contains the JSON data for decoding. Protocol has a name, a description, a number of recommended trials and a color. 
- `/test/`: contain the tests that can be run with a dart test


## How to run it : 
There is two solutions to run the program : 
- You have an environment with Dart installed, then you can type on your terminal : `$dart pub get` to download the dependencies and then `$dart run` to start the program. 
- You do not have an environment and you prefer do it online. You can use [replit](https://replit.com/).
    1. Create an account 
    2. Create a Repl with selecting the dart template. 
    3. Then on the replit, upload the project folder
    4. On the terminal, change directory to be at the root of the project
    5. type `dart run`
    6. You now have the program running and access to a dev web interface if you want to see the `/result_event`data. 




# Instructions : 

1. Implement a command to load a JSON file from a defined path:
`load $path`: Load protocols from the specified path.

2. Implement the following commands:
    - `protocols ls`: List the names of each loaded protocol.
    - `protocols $name`: Display the parameters of the specified protocol.

3. Implement the `run_protocol` command, which sends the desired protocol to the HTTPS server using a POST request to `/run_protocol`.
Example : 
``` CURL
curl -X POST -H "Content-Type: application/json" -d '{
  "name": "Anti",
  "description": "YourDescription",
  "trials": 5,
  "color": "red"
}' http://localhost:8080/run_protocol
```

4. Add an additional step in the `run_protocol` command that allows the user to modify the object parameters `trials` and `color` before sending the POST request.

5. Implement the `result` command, which subscribes to the Server-Sent Event route `/result_event` and retrieves the data. An event is send  for each trial once the computation is done, and when all event are sent, the server close the route.

    This route should be called after posting a `run_protocol`since it use this data to compute the results. 

    The event are not send in the right order in order to mock the actual asynchronous behavior.

    Results should be saved and displayed.

    Note : You should be able to test the event on a webbrowser with a GET request http://0.0.0.0:8080/result_event

6. Implement the `all_results` command, which displays the average result of the different runned protocols.


# Evaluation : 
The evalution will take into consideration : 
1. Respect of instructions
2. Code functionnalities 
3. Code quality and good practices : Make the code clean and scalable as if it was deployed in Production.




