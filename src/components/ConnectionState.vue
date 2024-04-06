<template>
  <div class="ap-status">
    <div class="ap-info">
      <h2 class="AP-Information-Text">AP Information</h2>
      <p><strong>AP ID:</strong> {{ apInfo.apId }}</p>
      <p><strong>Total Connections:</strong> {{ apInfo.totalConnections }}</p>
      <p><strong>AP Status:</strong> <span :class="getStatusClass">{{ apInfo.apStatus }}</span></p>
    </div>
    <div class="connected-devices">
      <h2>Connected Devices</h2>
      <table>
        <thead>
        <tr>
          <th>IP Address</th>
          <th>Last Connection Time</th>
          <th>Downloaded↓</th>
          <th>Uploaded↑</th>
          <th>Avg Download Speed↓</th>
          <th>Avg Upload Speed↑</th>
          <th>State</th>
        </tr>
        </thead>
        <tbody>
        <tr v-for="device in connectedDevices" :key="device.ip">
          <td>{{ device.ip }}</td>
          <td>{{ device.lastConnectionTime }}</td>
          <td>{{ device.totalDownload }}</td>
          <td>{{ device.totalUpload }}</td>
          <td>{{ device.avgDownloadSpeed }}</td>
          <td>{{ device.avgUploadSpeed }}</td>
          <td>{{ device.state }}</td>
        </tr>
        </tbody>
      </table>
    </div>
    <div class="buttons-container">
        <button type="button" @click="goBack" class="button-goBack">Go Back</button>
      <button type="button" class="button-refresh" @click="refreshApInfo">
        <svg
            xmlns="http://www.w3.org/2000/svg"
            width="16"
            height="16"
            fill="currentColor"
            class="bi bi-arrow-repeat"
            viewBox="0 0 16 16"
        >
          <path
              d="M11.534 7h3.932a.25.25 0 0 1 .192.41l-1.966 2.36a.25.25 0 0 1-.384 0l-1.966-2.36a.25.25 0 0 1
              .192-.41zm-11 2h3.932a.25.25 0 0 0 .192-.41L2.692 6.23a.25.25 0 0 0-.384 0L.342 8.59A.25.25 0 0 0 .534 9z"
          ></path>
          <path
              fill-rule="evenodd"
              d="M8 3c-1.552 0-2.94.707-3.857 1.818a.5.5 0 1 1-.771-.636A6.002 6.002 0 0 1 13.917
              7H12.9A5.002 5.002 0 0 0 8 3zM3.1 9a5.002 5.002 0 0 0 8.757 2.182.5.5 0 1 1 .771.636A6.002
               6.002 0 0 1 2.083 9H3.1z"
          ></path>
        </svg>
        Refresh
      </button>

    </div>
  </div>
</template>

<script>
import Swal from "sweetalert2";

const hostIP = window.location.host;

const IpAddress = hostIP.split(':')[0];
export default {
  name: "ConnectionState",

  data() {
    return {
      apInfo: {
        apId: null,
        totalConnections: 0,
        apStatus: "🔴Error",
      },
      connectedDevices: []
    };
  },

  async mounted() {
    const apAllInfo = await this.getApInfo()
    this.apInfo.apId = await this.getApId()
    if (this.apInfo.apId !== null) {
      this.apInfo.apStatus = "🟢Normal"
    }


    this.parseJsonApInfo(apAllInfo)
  },

  methods: {
    getStatusClass() {
      return this.apInfo.apStatus.includes('Normal') ? 'status-online' : 'status-offline';
    },
    async sendMessage(message) {
      return new Promise((resolve) => {

        const socket = new WebSocket(`ws://${IpAddress}:${9999}`);
        const messageJson = JSON.stringify(message)
        socket.onopen = () => {
          socket.send(messageJson);
        };

        socket.onmessage = (event) => {
          const validationResult = event.data;
          resolve(validationResult);
          socket.close();
        };
        socket.onerror = (error) => {
          console.error("WebSocket error:", error);
        };
        socket.onclose = (event) => {
          console.log("WebSocket connection closed:", event);
        };
      }).catch((error) => {
        console.log(error.message);
      });
    },


    async getApInfo() {
      const message = {requestAPAllInfo: "True"};
      return await this.sendMessage(message)
    },
    async getApId() {
      const message = {requestAPId: "True"};
      return await this.sendMessage(message)
    },
    parseJsonApInfo(apAllInfo) {
      if (apAllInfo === "error") {
        return;
      }
      let parsedApAllInfo;
      try {
        parsedApAllInfo = JSON.parse(apAllInfo)
      } catch (error) {
        console.error("Invalid JSON input:", error);
        return;
      }
      this.apInfo.totalConnections = parsedApAllInfo.client_length;
      for (const macAddress in parsedApAllInfo.clients) {
        if (Object.prototype.hasOwnProperty.call(parsedApAllInfo.clients, macAddress)) {
          const client = parsedApAllInfo.clients[macAddress];
          const connectedDevice = {
            ip: client.ip,
            lastConnectionTime: this.convertUnixTimestamp(client.active),
            totalDownload: (client.downloaded / 1024).toFixed(2) + " Mb",
            totalUpload: (client.uploaded / 1024).toFixed(2) + " Mb",
            avgUploadSpeed: (client.avg_up_speed / 1024).toFixed(2) + " Mb/s",
            avgDownloadSpeed: (client.avg_down_speed / 1024).toFixed(2) + " Mb/s",
            state: client.state
          };
          this.connectedDevices.push(connectedDevice);
        }
      }
    },
    convertUnixTimestamp(unixTimestamp) {
      const date = new Date(unixTimestamp * 1000);
      console.log(date.toLocaleString)
      return date.toLocaleString();
    },

    async refreshApInfo() {
      this.connectedDevices = []
      this.apInfo.totalConnections = 0
      this.apInfo.apId = null
      this.apInfo.apStatus = "🔄Loading"
      const apAllInfo = await this.getApInfo()
      this.apInfo.apId = await this.getApId()
      this.parseJsonApInfo(apAllInfo)
      if (this.apInfo.apId !== null) {
        this.apInfo.apStatus = "🟢Normal"
         Swal.fire({
          position: "center",
          icon: "success",
          title: "Refresh successful",
          showConfirmButton: false,
          timer: 1000
        });
      }
    },

    goBack() {
      this.$router.push('/AdminInterface')
    }
  }
}
</script>

<style scoped>
#app {
  font-family: "Avenir", Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-align: center;
  color: #2c3e50;
  margin-top: 60px;
}

.AP-Information-Text {
  text-align: center;
}

.ap-status {
  max-width: 1000px;
  text-align: left;
  margin: 0 auto;
  font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
}


.ap-info, .connected-devices {
  overflow-x: auto;
  max-width: 100%;
  background-color: #f5f5f5;
  padding: 20px;
  border-radius: 8px;
  margin-bottom: 20px;
}

h2 {
  color: #333;
}

.status-online {
  color: #2ecc71; /* Green color for normal status */
}

.status-offline {
  color: #e74c3c; /* Red color for abnormal status */
}

table {
  width: 100%;
  border-collapse: collapse;
  margin-top: 10px;
  overflow-x: auto;
  max-width: 100%;
}

th, td {
  border: 1px solid #ddd;
  padding: 12px;
  text-align: center;
  /*white-space: nowrap;*/
}

th {
  background-color: #f2f2f2;
  color: #333;
}

.buttons-container {
  display: flex;
  justify-content: space-between;
  margin-top: 20px;
}

.button-refresh,
.button-goBack{
  color: white;
  background-color: rgb(74, 148, 232);
  font-weight: 500;
  border-radius: 0.5rem;
  font-size: 1rem;
  line-height: 1.5rem;
  padding: 0.5rem 1.5rem;
  cursor: pointer;
  text-align: center;
  margin-right: 0.5rem;
  display: flex;
  align-items: center;
  border: none;
  position: relative;
  width: auto;
}

.button-goBack::after {
  content: url('../assets/back.svg');
  position: absolute;
  top: 10px;
  left: 5px;

}
.button-refresh:hover,
.button-goBack:hover {
  background-color: #5382dc;
}

.button-refresh svg{
  display: inline;
  width: 1.2rem;
  height: 1.2rem;
  margin-right: 0.15rem;
  color: white;
}

.button-refresh:focus svg {
  animation: spin_357 0.3s linear;
}

@keyframes spin_357 {
  from {
    transform: rotate(0deg);
  }

  to {
    transform: rotate(360deg);
  }
}

</style>