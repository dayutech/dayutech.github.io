<style>
#custom_bar {
  font-style: italic;
  position: fixed;
  top: 20%;
  right: 16px;
  left: auto;
  width: 240px;
  max-width: calc(100vw - 32px);
  box-shadow: 0 8px 20px rgba(0, 0, 0, 0.24);
  border-radius: 8px;
  overflow: hidden;
  z-index: 20;
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
  inset: 0;
  height: 100%;
  width: 100%;
  overflow: hidden;
}

.newYear-slider .swiper-wrapper {
  position: relative;
  width: 100%;
  height: 100%;
}

.newYear-slider .swiper-slide {
  position: absolute;
  inset: 0;
  background-size: cover;
  background-position: center;
  opacity: 0;
  transition: opacity 0.8s ease;
}

.newYear-slider .swiper-slide.is-active {
  opacity: 1;
}

#newYear-main {
  width: 100%;
  pointer-events: none;
  padding: 1rem;
  box-sizing: border-box;
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

#newYear-main .today {
  width: 100%;
  text-align: right;
  margin-top: 4px;
  padding-right: 3px;
  box-sizing: border-box;
}

#newYear-main .today .today-text {
  display: inline-block;
  max-width: 100%;
  text-align: right;
  font-size: 0.84rem;
  line-height: 1.2;
  white-space: nowrap;
  overflow: visible;
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

.post-body pre.mermaid {
  background: #fff !important;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  padding: 12px;
  display: flex;
  justify-content: center;
  align-items: center;
  text-align: center;
  overflow-x: auto;
}

.post-body pre.mermaid svg {
  background: transparent !important;
  max-width: 100%;
  margin: 0 auto;
}

@media (max-width: 767px), (hover: none), (pointer: coarse) {
  #custom_bar {
    display: none !important;
  }
}
</style>
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
            <p class="today"><span class="today-text"></span></p>
        </div>
    </div>
</aside>
<script data-pjax>
  (function() {
    const WEEK = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    const DAY_SECONDS = 86400;
    const DAY_MS = DAY_SECONDS * 1000;
    const BG_INTERVAL_MS = 10000;
    const state = window.__newYearCardState || (window.__newYearCardState = {
      timer: null,
      bgTimer: null,
      bgIndex: 0,
      pjaxBound: false,
      resizeBound: false,
      viewportBound: false,
      resizeTimer: null
    });
    const HOLIDAY_LABELS = [
      '正月初一',
      '正月初二',
      '正月初三',
      '正月初四',
      '正月初五',
      '正月初六',
      '正月初七',
      '正月初八',
      '正月初九',
      '正月初十',
      '正月十一',
      '正月十二',
      '正月十三',
      '正月十四',
      '正月十五'
    ];
    const SPECIAL_BLESSINGS = {
      0: '新春大吉',
      4: '迎财接福',
      14: '元宵喜乐'
    };
    const festivalCache = state.festivalCache || (state.festivalCache = {});
    const lunarFormatter = new Intl.DateTimeFormat('en-US-u-ca-chinese', {
      month: 'numeric',
      day: 'numeric'
    });

    function isDesktopView() {
      return window.matchMedia('(min-width: 992px) and (hover: hover) and (pointer: fine)').matches;
    }

    function placeCard(card) {
      const viewportPadding = 16;
      const preferredWidth = 240;
      const minWidth = 170;
      const minGapToContent = 8;
      const mainInner = document.querySelector('.main-inner');

      if (!mainInner) {
        card.style.width = preferredWidth + 'px';
        card.style.right = viewportPadding + 'px';
        card.style.left = 'auto';
        return true;
      }

      const rect = mainInner.getBoundingClientRect();
      const rightSpace = Math.floor(window.innerWidth - rect.right - viewportPadding);
      const maxWidthBySpace = rightSpace - minGapToContent;
      if (maxWidthBySpace < minWidth) return false;

      const nextWidth = Math.min(preferredWidth, maxWidthBySpace);
      card.style.width = nextWidth + 'px';
      card.style.right = viewportPadding + 'px';
      card.style.left = 'auto';
      return true;
    }

    function pad2(num) {
      return num > 9 ? String(num) : '0' + num;
    }

    function getDaysInMonth(year, month) {
      return new Date(year, month, 0).getDate();
    }

    function getSpringFestivalDate(year) {
      if (festivalCache[year]) return new Date(festivalCache[year].getTime());
      for (let month = 1; month <= 3; month += 1) {
        const days = getDaysInMonth(year, month);
        for (let day = 1; day <= days; day += 1) {
          const date = new Date(year, month - 1, day, 0, 0, 0);
          const parts = lunarFormatter.formatToParts(date);
          const lunarMonth = Number(parts.find(part => part.type === 'month')?.value);
          const lunarDay = Number(parts.find(part => part.type === 'day')?.value);
          if (lunarMonth === 1 && lunarDay === 1) {
            festivalCache[year] = date;
            return new Date(date.getTime());
          }
        }
      }
      const fallback = new Date(year, 1, 1, 0, 0, 0);
      festivalCache[year] = fallback;
      return new Date(fallback.getTime());
    }

    function setTodayText(now) {
      const todayNode = document.querySelector('#newYear .today-text') || document.querySelector('#newYear .today');
      if (!todayNode) return;
      todayNode.textContent = now.getFullYear() + '-' + pad2(now.getMonth() + 1) + '-' + pad2(now.getDate()) + ' ' + WEEK[now.getDay()];
    }

    function renderHolidayText(dayIndex, titleNode, timeNode) {
      const label = HOLIDAY_LABELS[dayIndex] || '春节';
      const blessing = SPECIAL_BLESSINGS[dayIndex] || '新年快乐';
      titleNode.textContent = label + ' · 新年快乐';
      timeNode.innerHTML = '<span class="happyNewYear">' + blessing + '</span>';
    }

    function renderNewYear() {
      const titleNode = document.querySelector('#newYear .title');
      const timeNode = document.querySelector('#newYear .newYear-time');
      if (!titleNode || !timeNode) return;

      const now = new Date();
      const nowMs = now.getTime();
      setTodayText(now);

      const currentYear = now.getFullYear();
      const currentYearFestival = getSpringFestivalDate(currentYear);
      const daysFromFestival = Math.floor((nowMs - currentYearFestival.getTime()) / DAY_MS);

      if (daysFromFestival >= 0 && daysFromFestival <= 14) {
        renderHolidayText(daysFromFestival, titleNode, timeNode);
        return;
      }

      const targetYear = nowMs < currentYearFestival.getTime() ? currentYear : currentYear + 1;
      const targetFestival = targetYear === currentYear ? currentYearFestival : getSpringFestivalDate(targetYear);
      let second = Math.floor((targetFestival.getTime() - nowMs) / 1000);
      if (second < 0) second = 0;

      titleNode.textContent = '距离' + targetYear + '年春节：';
      if (second > DAY_SECONDS) {
        timeNode.innerHTML = '<span class="day">' + Math.ceil(second / DAY_SECONDS) + '</span><span class="unit">天</span>';
        return;
      }

      const h = pad2(parseInt(second / 3600, 10));
      second %= 3600;
      const m = pad2(parseInt(second / 60, 10));
      second %= 60;
      const s = pad2(second);
      timeNode.innerHTML = '<span class="time">' + h + ':' + m + ':' + s + '</span>';
    }

    function clearNewYearTimer() {
      if (!state.timer) return;
      window.clearInterval(state.timer);
      state.timer = null;
    }

    function initNewYearTimer() {
      clearNewYearTimer();
      renderNewYear();
      state.timer = window.setInterval(renderNewYear, 1000);
    }

    function setActiveSlide(slides, nextIndex) {
      slides.forEach((slide, index) => {
        slide.classList.toggle('is-active', index === nextIndex);
      });
    }

    function stopBackgroundSlider() {
      if (!state.bgTimer) return;
      window.clearInterval(state.bgTimer);
      state.bgTimer = null;
    }

    function destroyBackgroundSlider() {
      stopBackgroundSlider();
      const slider = document.querySelector('.newYear-slider');
      if (slider) {
        slider.onmouseenter = null;
        slider.onmouseleave = null;
      }
    }

    function initBackgroundSlider() {
      destroyBackgroundSlider();
      const slider = document.querySelector('.newYear-slider');
      if (!slider) return;
      const slides = Array.from(slider.querySelectorAll('.swiper-slide'));
      if (slides.length === 0) return;

      state.bgIndex = 0;
      setActiveSlide(slides, state.bgIndex);

      if (slides.length === 1) return;

      const start = function() {
        if (state.bgTimer) return;
        state.bgTimer = window.setInterval(() => {
          state.bgIndex = (state.bgIndex + 1) % slides.length;
          setActiveSlide(slides, state.bgIndex);
        }, BG_INTERVAL_MS);
      };
      slider.onmouseenter = stopBackgroundSlider;
      slider.onmouseleave = start;
      start();
    }

    function initNewYearCard() {
      const card = document.querySelector('#custom_bar');
      if (!card) return;
      if (!isDesktopView()) {
        card.style.display = 'none';
        clearNewYearTimer();
        destroyBackgroundSlider();
        return;
      }
      if (!placeCard(card)) {
        card.style.display = 'none';
        clearNewYearTimer();
        destroyBackgroundSlider();
        return;
      }
      card.style.display = '';
      initBackgroundSlider();
      initNewYearTimer();
    }

    function onResize() {
      if (state.resizeTimer) window.clearTimeout(state.resizeTimer);
      state.resizeTimer = window.setTimeout(initNewYearCard, 160);
    }

    if (!state.pjaxBound) {
      document.addEventListener('pjax:complete', initNewYearCard);
      state.pjaxBound = true;
    }
    if (!state.resizeBound) {
      window.addEventListener('resize', onResize);
      state.resizeBound = true;
    }
    if (!state.viewportBound && window.visualViewport) {
      window.visualViewport.addEventListener('resize', onResize);
      state.viewportBound = true;
    }

    initNewYearCard();
  })();
</script>
