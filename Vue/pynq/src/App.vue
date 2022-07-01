<template>
  <div id="app">
    <div id="top_bar">
      <img src="@/assets/pynq_logo.png" alt="" id="logo"/>
    </div>
    <div id="toolbar">
      <el-tooltip style="margin-right: 20px;" class="item" effect="dark" content="Build and Upload" placement="bottom">
        <el-button type="primary" icon="el-icon-right" circle :loading="button_status.all" @click="src_all()"></el-button>
      </el-tooltip>
      <el-button-group style="margin-right: 20px;">
        <el-tooltip class="item" effect="dark" content="Build" placement="bottom">
          <el-button icon="el-icon-cpu" :loading="button_status.build" @click="src_build()" plain></el-button>
        </el-tooltip>
        <el-tooltip class="item" effect="dark" content="Upload" placement="bottom">
          <el-button icon="el-icon-upload2" :loading="button_status.upload" @click="src_upload()" plain></el-button>
        </el-tooltip>
        <el-tooltip class="item" effect="dark" content="Run" placement="bottom">
          <el-button icon="el-icon-caret-right" :loading="button_status.run" @click="src_run()" plain></el-button>
        </el-tooltip>
      </el-button-group>
      <el-select style="margin-right: 20px;" v-model="language_value" placeholder="Select Language">
        <el-option
        v-for="item in language_option"
        :key="item"
        :label="item"
        :value="item">
        </el-option>
      </el-select>
      <span>
        <div id="kernal_bar">
          <el-tooltip class="item" effect="dark" content="Restart kernel" placement="bottom">
            <el-button type="primary" circle icon="el-icon-refresh-right" @click="start_kernel"></el-button>
          </el-tooltip>
          <span>Kernel: </span>
          <i class="el-icon-s-help" :style="{color: kernel_color}"></i>
          <span>{{this.kernel_text}}</span>
        </div>
      </span>
    </div>
    <div id="content_area">
      <div id="code_area">
        <editor v-model="content" @init="editorInit" lang="c_cpp" theme="xcode" width="100%" height="80%"></editor>
        <el-input id="feedback" type="textarea" v-model="compile_feedback" readonly=true rows="7"></el-input>
      </div>
      <el-divider direction="vertical"></el-divider>
      <div id="analyse_area">
        <div id="control_panel">
        </div>
        <div id="refresh_control">
          <el-tooltip class="item" effect="dark" content="Refresh trace" placement="bottom">
            <el-button type="primary" icon="el-icon-refresh" circle @click="update_perf"></el-button>
          </el-tooltip>
          <el-checkbox style="margin-left: 5px;" v-model="auto_refresh">Auto Refresh</el-checkbox>
        </div>
        <div class="chart_area">
          <v-chart class="chart" :option="option" />
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import * as echarts from 'echarts'
import VChart from 'vue-echarts'
import axios from 'axios'
export default {
  name: 'App',
  components: {
    editor: require('vue2-ace-editor'),
    VChart
  },

  data () {
    return {
      language_option: [
        'C',
        'C++',
        'ASM'
      ],
      button_status: {
        all: false,
        build: false,
        upload: false,
        run: false
      },
      work_status: {
        all: 'idle',
        build: 'idle',
        upload: 'idle',
        run: 'idle'
      },

      language_value: 'C',
      content: '',
      compile_feedback: '12312313',
      auto_refresh: false,
      auto_refresh_timeout: {},
      kernel_color: 'red',
      kernel_text: 'Stopped',
      counter: 0,

      option: {
        tooltip: {
          formatter: function (params) {
            return params.marker + params.name + ': ' + params.value[3] + ' cycles\nFrom ' + params.value[1] + ' cycles\nTo ' + params.value[2] + ' Cycles'
          }
        },
        title: {
          text: 'Stack Trace',
          left: 'center'
        },
        dataZoom: [
          {
            type: 'slider',
            filterMode: 'weakFilter',
            showDataShadow: false,
            top: 400,
            labelFormatter: ''
          },
          {
            type: 'inside',
            filterMode: 'weakFilter'
          }
        ],
        grid: {
          height: 300
        },
        xAxis: {
          min: 0,
          scale: true,
          axisLabel: {
            formatter: '{value} cycles'
          }
        },
        yAxis: {
          data: [
            'Layer 1',
            'Layer 2',
            'Layer 3',
            'Layer 4',
            'Layer 5',
            'Layer 6',
            'Layer 7',
            'Layer 8',
            'Layer 9',
            'Layer 10'
          ],
          show: false
        },
        series: [
          {
            type: 'custom',
            renderItem: this.renderItem,
            itemStyle: {
              opacity: 0.8
            },
            encode: {
              x: [1, 2],
              y: 0
            },
            data: [
              {
                name: 'main',
                value: [0, 0, 1000, 1000],
                itemStyle: {
                  normal: {
                    color: '#7f7f7f'
                  }
                }
              }
            ]
          }
        ]
      },
      colors: {
        main: '#7f7f7f',
        interrupt: '#000000'
      },
      color_module: [
        '#ff0084',
        '#d72597',
        '#af4cab',
        '#7383c8',
        '#3abae3',
        '#19d8f2',
        '#00f0ff'
      ],
      perf: [
        {id: 0, t: 0},
        {id: 2, t: 100},
        {id: 3, t: 200},
        {id: 4, t: 300},
        {id: 6, t: 400},
        {id: 7, t: 500},
        {id: 5, t: 600}
      ],
      current_perf: 700,
      id_lut: [
        {name: 'main', type: 'start'},
        {name: 'main', type: 'end'},
        {name: 'func1', type: 'start'},
        {name: 'func1', type: 'end'},
        {name: 'func2', type: 'start'},
        {name: 'func2', type: 'end'},
        {name: 'func3', type: 'start'},
        {name: 'func3', type: 'end'}
      ]
    }
  },

  methods: {
    editorInit: function () {
      require('brace/ext/language_tools')
      require('brace/mode/c_cpp')
      require('brace/theme/xcode')
      require('brace/snippets/c_cpp')
    },

    renderItem: function (params, api) {
      var categoryIndex = api.value(0)
      var start = api.coord([api.value(1), categoryIndex])
      var end = api.coord([api.value(2), categoryIndex])
      var height = api.size([0, 1])[1]
      var rectShape = echarts.graphic.clipRectByRect(
        {
          x: start[0],
          y: start[1] - height / 2,
          width: end[0] - start[0],
          height: height
        },
        {
          x: params.coordSys.x,
          y: params.coordSys.y,
          width: params.coordSys.width,
          height: params.coordSys.height
        }
      )
      return (
        rectShape && {
          type: 'rect',
          transition: ['shape'],
          shape: rectShape,
          style: api.style()
        }
      )
    },

    update_option: function () {
      let stack = []
      let data = []
      this.perf.forEach(item => {
        let lut = this.id_lut[item.id]
        if (lut.type === 'start') {
          stack.push({name: lut.name, t: item.t})
        } else {
          let u = stack.pop()
          let color = ''
          if (u.name === lut.name) {
            if (u.name === 'main') {
              color = this.colors.main
            } else if (u.name === 'interrupt') {
              color = this.colors.interrupt
            } else {
              color = this.color_module[stack.length - 1]
            }
            data.push({
              name: lut.name,
              value: [stack.length, u.t, item.t, item.t - u.t],
              itemStyle: {
                color: color
              }
            })
          }
        }
      })
      if (stack.length !== 0) {
        for (let i = 0; i < stack.length; i++) {
          let u = stack.pop()
          let color = ''
          if (u.name === 'main') {
            color = this.colors.main
          } else if (u.name === 'interrupt') {
            color = this.colors.interrupt
          } else {
            color = this.color_module[stack.length + 1]
          }
          data.push({
            name: u.name,
            value: [stack.length, u.t, this.current_perf, this.current_perf - u.t],
            itemStyle: {
              color: color
            }
          })
        }
      }
      console.log(data)
      this.option.series[0].data = data
    },

    update_perf: function () {
      clearTimeout(this.auto_refresh_timeout)
      let _this = this
      axios.post('/method/perf/').then((response) => {
        for (let i = 0; i < response.data.data.length; i++) {
          _this.perf.push(response.data.data[i])
        }
        // update option
        let stack = []
        let data = []
        _this.perf.forEach(item => {
          let lut = _this.id_lut[item.id]
          console.log(_this.id_lut)
          console.log(item.id)
          if (lut.type === 'start') {
            stack.push({name: lut.name, t: item.t})
          } else {
            let u = stack.pop()
            let color = ''
            if (u.name === lut.name) {
              if (u.name === 'main') {
                color = _this.colors.main
              } else if (u.name === 'interrupt') {
                color = _this.colors.interrupt
              } else {
                color = _this.color_module[stack.length - 1]
              }
              data.push({
                name: lut.name,
                value: [stack.length, u.t, item.t, item.t - u.t],
                itemStyle: {
                  color: color
                }
              })
            }
          }
        })
        if (stack.length !== 0) {
          for (let i = 0; i < stack.length; i++) {
            let u = stack.pop()
            let color = ''
            if (u.name === 'main') {
              color = _this.colors.main
            } else if (u.name === 'interrupt') {
              color = _this.colors.interrupt
            } else {
              color = _this.color_module[stack.length + 1]
            }
            data.push({
              name: u.name,
              value: [stack.length, u.t, _this.current_perf, _this.current_perf - u.t],
              itemStyle: {
                color: color
              }
            })
          }
        }
        console.log(data)
        _this.option.series[0].data = data
        if (_this.auto_refresh) {
          _this.auto_refresh_timeout = setTimeout(_this.update_perf, 500)
        }
      })
    },

    src_build: function () {
      if (this.language_value !== '' && this.content !== '') {
        this.button_status.build = true
        let _this = this
        axios.post('/method/build/', {type: this.language_value, content: this.content}).then((response) => {
          _this.button_status.build = false
          if (response.data.code === 0) {
            _this.work_status.build = 'finish'
            _this.$notify({
              title: 'Successfully Build',
              position: 'bottom-left',
              type: 'success'
            })
            _this.compile_feedback = response.data.compile_feedback
          } else {
            _this.work_status.build = 'error'
            _this.$notify({
              title: 'Compile Error',
              position: 'top-left',
              type: 'error'
            })
            _this.compile_feedback = response.data.compile_feedback
          }
        }).catch(e => {
          console.log(e)
          _this.work_status.build = 'error'
          _this.button_status.build = false
          _this.$notify({
            title: 'Netword Error',
            position: 'top-left',
            type: 'error'
          })
        })
      } else {
        this.work_status.build = 'error'
        if (this.language_value === '') {
          this.$notify({
            title: 'Missing language choice',
            position: 'top-left',
            type: 'error'
          })
        }
        if (this.content === '') {
          this.$notify({
            title: 'Missing program content',
            position: 'top-left',
            type: 'error'
          })
        }
      }
    },

    src_upload: function () {
      this.button_status.upload = true
      axios.post('/method/upload/').then(() => {
        this.button_status.upload = false
        this.work_status.upload = 'finish'
        this.$notify({
          title: 'Successfully Upload',
          position: 'bottom-left',
          type: 'success'
        })
      }).catch(_err => {
        this.button_status.upload = false
        this.work_status.upload = 'error'
        this.$notify({
          title: 'Upload Error',
          position: 'top-left',
          type: 'error'
        })
      })
    },

    src_run: function () {
      this.button_status.run = true
      let _this = this
      axios.post('/method/run/').then((response) => {
        console.log('Run')
        _this.button_status.run = false
        _this.work_status.run = 'finish'
        _this.perf = []
        _this.id_lut = response.data.data
        _this.update_perf()
        _this.$notify({
          title: 'Successfully Run',
          position: 'bottom-left',
          type: 'success'
        })
      }).catch(e => {
        _this.work_status.run = 'error'
        _this.button_status.run = false
        _this.$notify({
          title: 'Run Error',
          position: 'top-left',
          type: 'error'
        })
      })
    },

    src_all: function () {
      let _this = this
      this.button_status.all = true
      this.button_status.build = true
      this.button_status.upload = true
      this.button_status.run = true
      this.work_status.build = 'idle'
      this.work_status.upload = 'idle'
      this.work_status.run = 'idle'
      this.src_build()
      let u = setInterval(() => {
        if (_this.work_status.build === 'finish') {
          _this.src_upload()
          clearInterval(u)
          setTimeout(() => {
            if (_this.work_status.upload === 'finish') {
              _this.src_run()
              setTimeout(() => {
                if (_this.work_status.run === 'finish') {
                  _this.button_status.all = false
                } else {
                  _this.button_status.all = false
                  _this.button_status.build = false
                  _this.button_status.upload = false
                  _this.button_status.run = false
                }
              }, 500)
            } else {
              _this.button_status.all = false
              _this.button_status.build = false
              _this.button_status.upload = false
              _this.button_status.run = false
            }
          }, 500)
        } else {
          _this.counter++
          if (_this.counter >= 20) {
            _this.button_status.all = false
            _this.button_status.build = false
            _this.button_status.upload = false
            _this.button_status.run = false
            clearInterval(u)
          }
          if (_this.work_status.build === 'error') {
            _this.button_status.all = false
            _this.button_status.build = false
            _this.button_status.upload = false
            _this.button_status.run = false
            clearInterval(u)
          }
        }
      }, 500)
    },

    start_kernel: function () {
      this.kernel_color = 'orange'
      this.kernel_text = 'Starting'
      axios.post('/method/init/').then(response => {
        if (response.data.code === 0) {
          this.kernel_color = 'green'
          this.kernel_text = 'Ready'
        } else {
          this.kernel_color = 'red'
          this.kernel_text = 'Stopped'
          this.$notify({
            title: 'Kernel Error',
            position: 'top-left',
            type: 'error'
          })
        }
      }).catch(e => {
        this.kernel_color = 'red'
        this.kernel_text = 'Stopped'
        this.$notify({
          title: 'Kernel Error & Network Error',
          position: 'top-left',
          type: 'error'
        })
      })
    }

  },

  mounted () {
    this.start_kernel()
  }
}
</script>

<style>
#app {
  font-family: 'Avenir', Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-align: left;
  color: #2c3e50;
  height: 100%;
  width: 100%;
}

#top_bar{
  width: 100%;
}

#toolbar{
  border-radius: 20px;
  margin: 10px;
  display: flex;
  align-items: center;
}

#content_area{
  height: calc(100% - 120px);
  width: 100%;
  display: flex;
  justify-content: space-around;
  align-items: flex-start;
}

#code_area{
  background-color: white;
  width: 47%;
  height: 100%;
  display:inline-block;
}

#analyse_area{
  background-color: white;
  width: 47%;
  height: 100%;
  display: flex;
  flex-direction: column;
  align-items: center;
}

#control_panel{
  display: flex;
  height: 240px;
  width: calc(100% - 40px);
  background-color: lightgrey;
  border-radius: 20px;
  padding: 20px;
}

.chart_area{
  height: calc(100% - 240px);
  width: 100%;
}

.chart{
  height: 100%;
  width: 100%;
}

#feedback{
  width: 100%;
}

#refresh_control{
  display: flex;
  align-items: center;
  align-self: flex-start;
}
</style>
