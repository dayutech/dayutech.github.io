<style>
#custom_bar {
  font-style: italic;
  position: fixed;
  top: 20%;
  right: 16px;
  left: auto;
  width: 240px;
  max-width: calc(100vw - 32px);
  display: flex;
  flex-direction: column;
  gap: 8px;
  overflow: visible;
  z-index: 20;
}
/* 新年侧边栏 */
#newYear {
  position: relative;
  color: white;
  padding: 0 !important;
  border-radius: 8px;
  overflow: hidden;
  box-shadow: 0 6px 14px rgba(0, 0, 0, 0.22);
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

#festivalNext {
  color: #fff;
  border-radius: 8px;
  padding: 10px 12px;
  background: linear-gradient(145deg, #b91c1c, #dc2626 55%, #f97316);
  box-shadow: 0 4px 10px rgba(0, 0, 0, 0.18);
}

#festivalNext p,
#festivalNext h4 {
  margin: 0;
  color: inherit;
  font-weight: normal;
}

#festivalNext .festival-next-title {
  font-size: 0.94rem;
  margin-bottom: 6px;
  line-height: 1.3;
}

#festivalNext .festival-next-time {
  text-align: center;
  font-weight: bold;
  margin: 4px 0 6px;
}

#festivalNext .festival-next-time .festival-day {
  font-size: 2.05rem;
  letter-spacing: 1px;
}

#festivalNext .festival-next-time .festival-unit {
  font-size: 0.88rem;
  margin-left: 2px;
}

#festivalNext .festival-next-time .festival-now {
  font-size: 1.3rem;
}

#festivalNext .festival-next-desc {
  font-size: 0.78rem;
  line-height: 1.45;
  margin-bottom: 6px;
}

#festivalNext .festival-next-list {
  font-size: 0.7rem;
  line-height: 1.35;
  opacity: 0.95;
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
    <div id="festivalNext">
        <p class="festival-next-title"></p>
        <div class="festival-next-time"></div>
        <p class="festival-next-desc"></p>
        <p class="festival-next-list"></p>
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
      resizeTimer: null,
      nextFestivalCacheKey: '',
      nextFestivalCache: null
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
    const TRADITIONAL_FESTIVALS = [
      { id: 'chuxi', name: '除夕', type: 'special', description: '除夕是农历岁末最后一天，家人团圆守岁，辞旧迎新。' },
      { id: 'spring', name: '春节', type: 'lunar', month: 1, day: 1, description: '春节是中华民族最重要的传统节日，象征新年新气象。' },
      { id: 'yuanxiao', name: '元宵节', type: 'lunar', month: 1, day: 15, description: '元宵节在正月十五，赏花灯、吃元宵，寓意团圆美满。' },
      { id: 'longtaitou', name: '龙抬头', type: 'lunar', month: 2, day: 2, description: '二月二龙抬头，寓意万物生发、风调雨顺。' },
      { id: 'shangsi', name: '上巳节', type: 'lunar', month: 3, day: 3, description: '上巳节是春季祓禊传统节日，寓意祈福纳祥、清洁身心。' },
      { id: 'qingming', name: '清明节', type: 'solar', month: 4, description: '清明节兼具节气与节日属性，人们祭祖追思、踏青亲近自然。' },
      { id: 'duanwu', name: '端午节', type: 'lunar', month: 5, day: 5, description: '端午节在五月初五，赛龙舟、食粽子，传承家国文化记忆。' },
      { id: 'qixi', name: '七夕节', type: 'lunar', month: 7, day: 7, description: '七夕节是传统乞巧与爱情文化节日，寄托对美好生活的向往。' },
      { id: 'zhongyuan', name: '中元节', type: 'lunar', month: 7, day: 15, description: '中元节在七月十五，慎终追远、敬祖感恩。' },
      { id: 'zhongqiu', name: '中秋节', type: 'lunar', month: 8, day: 15, description: '中秋节在八月十五，赏月团聚，寓意阖家团圆。' },
      { id: 'chongyang', name: '重阳节', type: 'lunar', month: 9, day: 9, description: '重阳节在九月初九，登高望远、敬老祈安。' },
      { id: 'hanyi', name: '寒衣节', type: 'lunar', month: 10, day: 1, description: '寒衣节在十月初一，表达慎终追远与关怀故人的情感。' },
      { id: 'xiayuan', name: '下元节', type: 'lunar', month: 10, day: 15, description: '下元节在十月十五，传统上有祈福消灾、感恩天地之意。' },
      { id: 'laba', name: '腊八节', type: 'lunar', month: 12, day: 8, description: '腊八节在腊月初八，喝腊八粥，寓意丰收与吉祥。' },
      { id: 'xiaonian', name: '小年', type: 'lunar', month: 12, day: 23, description: '小年是春节前的重要节俗节点，家家扫尘祭灶，准备迎新。' }
    ];
    const FESTIVAL_NAME_LIST = TRADITIONAL_FESTIVALS.map(item => item.name).join('、');
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

    function parsePartNumber(value) {
      const matched = String(value || '').match(/\d+/);
      return matched ? Number(matched[0]) : NaN;
    }

    function getLunarMonthDay(date) {
      const parts = lunarFormatter.formatToParts(date);
      const lunarMonth = parsePartNumber(parts.find(part => part.type === 'month')?.value);
      const lunarDay = parsePartNumber(parts.find(part => part.type === 'day')?.value);
      if (!Number.isFinite(lunarMonth) || !Number.isFinite(lunarDay)) return null;
      return { month: lunarMonth, day: lunarDay };
    }

    function getQingmingDay(year) {
      const y = year % 100;
      let day = Math.floor(y * 0.2422 + 4.81) - Math.floor((y - 1) / 4);
      const specialYears = {
        2008: 4,
        2016: 4
      };
      if (specialYears[year]) day = specialYears[year];
      return day;
    }

    function isChineseNewYearEve(date) {
      const tomorrow = new Date(date.getFullYear(), date.getMonth(), date.getDate() + 1, 12, 0, 0, 0);
      const lunarTomorrow = getLunarMonthDay(tomorrow);
      return !!lunarTomorrow && lunarTomorrow.month === 1 && lunarTomorrow.day === 1;
    }

    function getFestivalsOnDate(date) {
      const solarMonth = date.getMonth() + 1;
      const solarDay = date.getDate();
      const lunar = getLunarMonthDay(date);
      const matched = [];

      TRADITIONAL_FESTIVALS.forEach(item => {
        if (item.type === 'lunar') {
          if (lunar && lunar.month === item.month && lunar.day === item.day) matched.push(item);
          return;
        }
        if (item.type === 'solar') {
          const day = item.name === '清明节' ? getQingmingDay(date.getFullYear()) : item.day;
          if (solarMonth === item.month && solarDay === day) matched.push(item);
          return;
        }
        if (item.type === 'special' && item.name === '除夕' && isChineseNewYearEve(date)) {
          matched.push(item);
        }
      });

      return matched;
    }

    function getUpcomingTraditionalFestival(todayNoon) {
      for (let offset = 0; offset <= 420; offset += 1) {
        const date = new Date(todayNoon.getFullYear(), todayNoon.getMonth(), todayNoon.getDate() + offset, 12, 0, 0, 0);
        const festivals = getFestivalsOnDate(date);
        if (festivals.length > 0) {
          return { date, festivals, days: offset };
        }
      }
      return null;
    }

    function getSpringFestivalDate(year) {
      if (festivalCache[year]) return new Date(festivalCache[year].getTime());
      for (let month = 1; month <= 3; month += 1) {
        const days = getDaysInMonth(year, month);
        for (let day = 1; day <= days; day += 1) {
          const date = new Date(year, month - 1, day, 12, 0, 0, 0);
          const lunar = getLunarMonthDay(date);
          if (lunar && lunar.month === 1 && lunar.day === 1) {
            festivalCache[year] = date;
            return new Date(date.getTime());
          }
        }
      }
      const fallback = new Date(year, 1, 1, 12, 0, 0, 0);
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

    function getDateKey(date) {
      return date.getFullYear() + '-' + pad2(date.getMonth() + 1) + '-' + pad2(date.getDate());
    }

    function renderNextFestivalCard(now) {
      const box = document.querySelector('#festivalNext');
      if (!box) return;
      const titleNode = box.querySelector('.festival-next-title');
      const timeNode = box.querySelector('.festival-next-time');
      const descNode = box.querySelector('.festival-next-desc');
      const listNode = box.querySelector('.festival-next-list');
      if (!titleNode || !timeNode || !descNode || !listNode) return;

      const todayNoon = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 12, 0, 0, 0);
      const key = getDateKey(todayNoon);
      if (state.nextFestivalCacheKey !== key) {
        state.nextFestivalCache = getUpcomingTraditionalFestival(todayNoon);
        state.nextFestivalCacheKey = key;
      }

      const nextFestival = state.nextFestivalCache;
      listNode.textContent = '传统节日：' + FESTIVAL_NAME_LIST;
      if (!nextFestival) {
        titleNode.textContent = '未找到节日数据';
        timeNode.textContent = '--';
        descNode.textContent = '';
        return;
      }

      const names = nextFestival.festivals.map(item => item.name).join('、');
      const descriptions = nextFestival.festivals.map(item => item.description).join(' ');
      if (nextFestival.days === 0) {
        titleNode.textContent = '今天是' + names;
        timeNode.innerHTML = '<span class="festival-now">节日快乐</span>';
        descNode.textContent = descriptions;
        return;
      }

      titleNode.textContent = '距离下一个传统节日：' + names;
      timeNode.innerHTML = '<span class="festival-day">' + nextFestival.days + '</span><span class="festival-unit">天</span>';
      descNode.textContent = nextFestival.festivals[0].description;
    }

    function renderNewYear() {
      const titleNode = document.querySelector('#newYear .title');
      const timeNode = document.querySelector('#newYear .newYear-time');
      if (!titleNode || !timeNode) return;

      const now = new Date();
      const nowMs = now.getTime();
      setTodayText(now);
      renderNextFestivalCard(now);

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
