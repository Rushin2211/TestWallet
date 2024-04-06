<template>
  <div id="app">
    <h1>Welcome to SONY WiFi-NFT Wallet!</h1>
    <button name="welcome" v-on:click="SkipToLoginComponent" class="UseNowBtn">Use Now</button>
  </div>
</template>

<script>
export default {
  name: 'WelcomeToUse',

  methods: {
    SkipToLoginComponent() {
      this.$router.push('/LogIn');
    }
  }
}
</script>

<style scoped>
#app {
  text-align: center;
  padding: 20px;
}

h1 {
  font-size: 4.5vw; /* 使用vw单位使标题大小随视口宽度变化 */
  white-space: nowrap; /* 防止标题换行 */
  margin-bottom: 30px; /* 添加一些底部间距 */
}

.UseNowBtn {
  width: 50%; /* 设置按钮宽度为父元素宽度的一半 */
  max-width: 230px; /* 设置按钮最大宽度 */
  height: 70px;
  background-color: rgb(74, 148, 232);
  color: white;
  border-color: transparent;
  padding: 10px 20px;
  font-size: 4vw; /* 使用vw单位使按钮字体大小随视口宽度变化 */
  box-shadow: 2px 2px 5px rgba(0, 0, 0, 0.2);
  border-radius: 20px;
}

.UseNowBtn:active {
  /*font-size: 2.1vw; !* 使用vw单位使按钮字体大小随视口宽度变化 *!*/
  /*background-color: rgb(128, 128, 128);*/
  transform: scale(0.95);
}

@media screen and (min-width: 768px) {
  /* 对于宽度大于等于768px的设备 */
  h1 {
    font-size: 40px; /* 固定标题字体大小 */
  }

  .UseNowBtn {
    font-size: 26px; /* 固定按钮字体大小 */
  }
}
</style>
