# Flow Of The API

This is how the test implementation works currently.

1. (Possibly, and not yet implemented) Client queries the server: available memory, jobs running, jobs queued, etc.

2. Client starts a session (this may be implied when e.g. the client sends some parameters, or explicit). Possibly an API token is provided. Server side, defautlt parameters and outputs are created and assigned to the session.

Note: parameters can be divided into policy parameters (e.g. tax rates) and run settings (e.g. numbers of households to run over).These are treated as seperate records;

3. Optionally, client queries the server for the required structure of inputs and outputs. The response might be in JSON, XML etc. and includes names of parameters, minima and maxima, preferred formats, etc. Possibly the client builds a UI automatically from this information (I have a rough version of this). Alternatively, the client might have a pre-built UI, as in the Scotben demo. Server site, these replies might simply be some static files;

4. Client gets inputs, probably from a web form, packages them in the format required by (3) and sends them to the server. This may happen serveral times. Server side, the parameters are validated and either an error message is sent back or the session parameters are updated.

5. The client runs the model. Server side:
 - a run data structure is created for monitoring and holding output in a server dictionary. This is keyed by a hash of the parameter values - if the key already exists, we send back stored results instantly. The run id is added to the session information for the user;
 - if no instant reply, the set of parameters is placed in a job queue. Jobs are pulled out of the queue by model run workers.

 Doing it this way allows the server to respond instantly to the run submission. In the test implementation the job queue is simply an Channel structure on the server, but bigger implementations might use proper queue software like Torque (I've used this before)

6. The server monitors the job. In the test implementation, we use an observer/observable pattern to write a short record to the run dictionary every time some event happens (additional 1,000 households processed, output creation phase reached etc.). Client side, a progress bar is drawn by repeatedly querying the server for run progress.

7. When the phase of the run is 'complete', the client begins making requests for output. In the test implementation, all the output is in json which is parsed into tables and graphs client-side. (The library for this is already huge).

8. Optionally, the session is destroyed.




