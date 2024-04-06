<template>
  <div id="app">
    <h1>New User</h1>
    <button class="btn" v-on:click="Exit">Exit</button>
  </div>
</template>

<script>
export default {
  name: "NewUser",
  methods: {
    Exit() {
      this.$router.push('/LogIn')
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

.btn {
  width: 250px;
  height: 70px;
  background-color: rgb(74, 148, 232);
  color: white;
  border-color: transparent;
  padding: 10px 20px;
  font-size: 18px;
  box-shadow: 2px 2px 5px rgba(0, 0, 0, 0.2);
  border-radius: 20px;
  text-align: center;
}

.btn:hover {
  color: white;
  background-color: rgb(74, 148, 232);
}

.btn:active {
  font-size: 21px;
  color: white;
  background-color: rgb(128, 128, 128);
}
</style>