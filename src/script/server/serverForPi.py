import asyncio
import json
import secrets
import subprocess
import time

import websockets

import verify


def execute_ndsctl_deauth(client_ip):
    command = f"sudo ndsctl deauth {client_ip}"
    try:
        subprocess.run(command, shell=True, check=True)
        print(f"{client_ip} authorization revoked")
    except subprocess.CalledProcessError as e:
        print(f"Cancel authorization command execution failed: {e}")

    print(client_ip + " has been deleted")


def execute_ndsctl_auth(client_ip):
    command = f"sudo ndsctl auth {client_ip}"
    try:
        subprocess.run(command, shell=True, check=True)
        print(f"{client_ip} authorization successful")
    except subprocess.CalledProcessError as e:
        print(f"Authorization command execution failed: {e}")
    print(client_ip + " has already joined")


def generate_random_hex_hash(length=64):
    # Generate a random byte string with length to length*2 (because a hexadecimal character corresponds to two bytes)
    random_bytes = secrets.token_bytes(length // 2)

    # Convert the byte string to hexadecimal representation
    random_hex_hash = random_bytes.hex()

    return random_hex_hash


def get_AP_Status():
    command = "sudo ndsctl json"
    try:
        apInfo = subprocess.run(command, shell=True, check=True, capture_output=True, text=True)
        return apInfo.stdout
    except subprocess.CalledProcessError:
        return "error"


class WebSocketServer:
    def __init__(self, config_path='config.json'):
        with open(config_path, 'r') as config_file:
            self.config = json.load(config_file)

        self.contract_address = self.config["contractAddress"]
        self.server_port = self.config["serverPort"]
        self.server_ip = self.config["serverIP"]
        self.AP_id = self.config["accessPointId"]
        # Create an event to control the server loop
        self.stop_server_event = asyncio.Event()
        self.control_set = {}

    # Process a single websocket connection, receive messages from the client, validate the client,
    # and send the verification result response to the client.
    async def handle_websocket(self, websocket):
        try:
            while not self.stop_server_event.is_set():
                validation_results = False
                access_IP = websocket.remote_address
                # Handle received messages
                try:
                    recv_data = await websocket.recv()
                    print(f"Received message from {access_IP[0]}: {recv_data}")
                    try:
                        recv_json_data = json.loads(recv_data)
                        print(recv_json_data)
                        if 'authenticationRequest' in recv_json_data and \
                                recv_json_data['authenticationRequest'] == 'requestValidation':

                            # Generate a session ID
                            session_id = generate_random_hex_hash()
                            # Send the session ID to the client
                            await websocket.send(session_id)
                            # Wait for the client to send the signature
                            signature_data = await websocket.recv()
                            signature_json_data = json.loads(signature_data)
                            print(signature_json_data)
                            if 'tokenId' in signature_json_data and 'signatureResult' in signature_json_data:
                                token_id = str(signature_json_data['tokenId'])
                                signature_result = signature_json_data['signatureResult']

                                v = verify.VerifyNftOwnership(
                                    self.contract_address, session_id, token_id, self.AP_id, signature_result
                                )
                                validation_results = v.verify()

                                if validation_results:
                                    self.control_set[access_IP[0]] = v.getExpirationTime()
                                    execute_ndsctl_auth(access_IP[0])
                                    print("Verification result: " + str(validation_results))
                        elif 'requestAPAllInfo' in recv_json_data and recv_json_data['requestAPAllInfo'] == 'True':
                            toSendResult = get_AP_Status()
                            await websocket.send(toSendResult)
                            continue
                        elif 'requestAPId' in recv_json_data and recv_json_data['requestAPId'] == 'True':
                            toSendResult = self.AP_id
                            await websocket.send(toSendResult)
                            continue
                    except json.JSONDecodeError as e:
                        print(f"Error decoding JSON: {e}")
                except websockets.ConnectionClosedError:
                    print("WebSocket connection closed")
                    break  # Exit the loop, terminate connection handling

                # Reply with the validation result to the client
                response_message = str(validation_results)
                print("response_message:" + response_message)
                await websocket.send(response_message)

        except websockets.ConnectionClosedOK:
            print(f"AP is listening at {self.server_ip}:{self.server_port}...")

    def start_daemon_thread(self, loop):
        async def daemon_thread():
            while not self.stop_server_event.is_set():

                current_time = time.time()
                expired_ips = [ip for ip, expiration_time in self.control_set.items() if expiration_time < current_time]
                for expired_ip in expired_ips:
                    execute_ndsctl_deauth(expired_ip)
                    del self.control_set[expired_ip]

                await asyncio.sleep(1)

        # Create and start the guardian thread
        loop.create_task(daemon_thread())

    async def start_server(self):
        try:
            # Surveillance on the designated IP address and port
            async with websockets.serve(self.handle_websocket, self.server_ip, self.server_port):
                print("WebSocket server has started")
                print(f"AP is listening at {self.server_ip}:{self.server_port}...")
                loop = asyncio.get_event_loop()
                self.start_daemon_thread(loop)
                # Waiting for the event to be set, that is, waiting to stop the server
                await self.stop_server_event.wait()
        except Exception as e:
            print(f"error: {e}")

    def run(self):
        try:
            loop = asyncio.get_event_loop()
            loop.run_until_complete(self.start_server())
        except KeyboardInterrupt:
            print("The server has stopped.")
            self.stop_server_event.set()  # Setting event to stop the server


# Create an instance of the WebSocketServer and run it
if __name__ == "__main__":
    server = WebSocketServer()
    server.run()
