<template>
  <div id="app">
    <h1>Network Connection Successful</h1>

    <br />
    <br />

    <p>Remaining Service Time:</p>

    <div id="countdown">
      {{ count }}
      <small>s</small>
    </div>

    <br />
    <br />
    <br />
    <br />

    <button name="BackToBackToLoginPage" class="btn" v-on:click="Back">Back</button>

    <br />
    <br />
    <br />

  </div>
</template>

<script>
import Swal from "sweetalert2";

export default {
  name: "ConnectSuccess",

  props: {
    msg: String
  },

  data: function() {
    return {
      // Retrieve the value of countdown time count from locally saved data with key Countdown
      count: window.sessionStorage.getItem("Countdown"),
    };
  },

  // Automatically call the countdown function when opening this page, executed every 1000ms (1s)
  mounted() {
    this.timer = setInterval(() => {
      if (this.count > 0) {
        this.count--;
      } else {
        clearInterval(this.timer);
        Swal.fire({
            position: "center",
            icon: "warning",
            title: "The remaining service time is not sufficient",
            showConfirmButton: false,
            timer: 2500
        });
        this.$router.push('/UserInterface');
      }
    }, 1000);
  },

  methods: {
    Back() {
      setTimeout(this.BackToAccountDetailsPage, 700)
    },

    BackToAccountDetailsPage() {
      this.$router.push('/UserInterface')
    }
  }
};
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>
#app {
  font-family: "Avenir", Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-align: center;
  color: #2c3e50;
  margin-top: 60px;
}

p {
  font-size: 30px;
  font-weight: bold;
}

#countdown {
  font-size: 50px;
  font-weight: bold;
}

.btn {
  width: 260px;
  height: 70px;
  background-color: rgb(74, 148, 232);
  color: white;
  border-color: transparent;
  padding: 10px 20px;
  font-size: 20px;
  box-shadow: 2px 2px 5px rgba(0, 0, 0, 0.2);
  border-radius: 20px;
  text-align: center;
}

.btn:active {
  font-size: 21px;
  color: white;
  background-color: rgb(128, 128, 128);
}


small {
  font-size: 50px;
}
</style>
