<style>
#custom_bar {
  float: right;
  font-style: italic;
  background-color: lightgray;
  position: fixed;
  top: 20%;
  right: 50px;
  box-shadow: 15px 10px 10px gray;
}
/* 新年侧边栏 */
#newYear {
  color: white;
  padding: 0 !important;
}

#newYear p,
#newYear h3 {
  font-weight: normal;
  color: inherit;
  margin: 0;
}

#newYear .item-headline {
  display: none;
}

.newYear-slider {
  position: absolute;
  left: 0;
  top: 0;
  height: 100%;
  width: 100%;
}

.newYear-slider .swiper-slide {
  min-height: 160px;
  min-width: 210px;
  background-size: cover;
  position: absolute;
  left: 0;
  top: 0;
  height: 100%;
  width: 100%;
}

#newYear-main {
  width: 100%;
  pointer-events: none;
  padding: 1rem;
  position: relative;
  left: 0;
  top: 0;
  z-index: 1;
}

#newYear-main * {
  position: relative;
  line-height: 1.3;
}

#newYear-main .time,
#newYear-main .happyNewYear {
  font-size: 3rem;
  margin: 8px 0;
  display: block;
}

#newYear-main .newYear-time {
  font-weight: bold;
  text-align: center;
}

#newYear-main .day {
  font-size: 4rem;
  letter-spacing: 6px;
  margin-right: -6px;
}

#newYear-main .unit {
  font-size: 1rem;
}

#newYear-main .mask {
  position: absolute;
  left: 0;
  top: 0;
  height: 100%;
  width: 100%;
  background-color: rgba(0, 0, 0, .2);
}

[data-theme=dark] #newYear-main .mask {
  background-color: rgba(0, 0, 0, .3);
}
</style>
<link data-pjax rel="stylesheet" href="https://lf9-cdn-tos.bytecdntp.com/cdn/expire-1-M/Swiper/8.0.6/swiper-bundle.min.css">
<aside id="custom_bar">
    <div id="newYear">
        <div class="newYear-slider">
            <div class="swiper-wrapper">
                <div class="swiper-slide" style="background-image:url(/images/ma1.jpg)"></div>
                <div class="swiper-slide" style="background-image:url(/images/ma2.jpg)"></div>
                <div class="swiper-slide" style="background-image:url(/images/ma3.jpg)"></div>
                <div class="swiper-slide" style="background-image:url(/images/ma4.jpg)"></div>
            </div>
        </div>
        <div id="newYear-main">
            <div class="mask"></div>
            <p class="title"></p>
            <div class="newYear-time"></div>
            <p class="today" style="text-align: right;"></p>
        </div>
    </div>
</aside>
<script data-pjax src="https://lf3-cdn-tos.bytecdntp.com/cdn/expire-1-M/Swiper/8.0.6/swiper-bundle.min.js"></script>
<script data-pjax>
    function newYear() {
    if (!document.querySelector('#newYear')) return;
    // 新年时间戳 and 星期对象
    let SpringFestival = new Date('2026-02-17 00:00:00')
    let newYear = SpringFestival.getTime() / 1000,
        week = { 0: '周日', 1: '周一', 2: '周二', 3: '周三', 4: '周四', 5: '周五', 6: '周六' }
    function nol(h) { h = Number(h); return h > 9 ? h : '0' + h; }
    time();

    function time() {
        // 现在 时间对象
        let now = new Date();

        // 右下角 今天
        document.querySelector('#newYear .today').innerHTML = now.getFullYear() + '-' + (now.getMonth() + 1) + '-' + now.getDate() + ' ' + week[now.getDay()]

        // 现在与新年相差秒数
        let second = newYear - Math.round(now.getTime() / 1000);

        // 小于0则表示已经过年
        if (second < 0) {
        window.newYearTimer = null
        document.querySelector('#newYear .title').innerHTML = 'Happy New Year!';
        document.querySelector('#newYear .newYear-time').innerHTML = '<span class="happyNewYear">新年快乐</span>';
        } else {
        // 大于0则还未过年
        document.querySelector('#newYear .title').innerHTML = '距离' + SpringFestival.getFullYear() + '年春节：'
        // 大于一天则直接渲染天数
        if (second > 86400) {
            document.querySelector('#newYear .newYear-time').innerHTML = `<span class="day">${Math.ceil(second / 86400)}</span><span class="unit">天</span>`
        } else {
            // 小于一天则使用时分秒计时。
            let h = nol(parseInt(second / 3600));
            second %= 3600;
            let m = nol(parseInt(second / 60));
            second %= 60;
            let s = nol(second);
            document.querySelector('#newYear .newYear-time').innerHTML = `<span class="time">${h}:${m}:${s}</span></span>`;
            // 计时
            if (!window.newYearTimer) window.newYearTimer = setInterval(time, 1000);
        }
        }
    }
    }

    function newYearSwiper() {
    var swiper = new Swiper('.newYear-slider', {
        passiveListeners: true,
        loop: true,
        // autoplay: false,
        autoplay: {
        disableOnInteraction: true,
        delay: 5000
        },
        effect: 'fade',
        mousewheel: true,
        autoHeight: true
    });

    var comtainer = document.querySelector('.newYear-slider');
    if (comtainer !== null) {
        comtainer.onmouseenter = () => { swiper.autoplay.stop() };
        comtainer.onmouseleave = () => { swiper.autoplay.start() };
    }
    }

    // 适配了pjax
    function whenDOMReady() {
    // pjax加载完成（切换页面）后需要执行的函数和代码
    newYear()
    newYearSwiper()
    }

    whenDOMReady() // 打开网站先执行一次
    document.addEventListener("pjax:complete", whenDOMReady) // pjax加载完成（切换页面）后再执行一次
</script>
