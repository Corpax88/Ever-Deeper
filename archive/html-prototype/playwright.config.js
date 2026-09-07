const {defineConfig,devices}=require('@playwright/test');

module.exports=defineConfig({
  testDir:'./tests/browser',
  timeout:60000,
  fullyParallel:false,
  workers:1,
  reporter:'line',
  use:{
    baseURL:'http://127.0.0.1:4180',
    trace:'on-first-retry',
    screenshot:'only-on-failure'
  },
  projects:[
    {name:'desktop',use:{...devices['Desktop Chrome'],viewport:{width:1280,height:800}}},
    {name:'iphone',use:{...devices['iPhone 13'],browserName:'chromium'}}
  ]
});
