{% macro render(display_toc) %}
  <div class="toggle sidebar-toggle">
    <span class="toggle-line toggle-line-first"></span>
    <span class="toggle-line toggle-line-middle"></span>
    <span class="toggle-line toggle-line-last"></span>
  </div>

  <aside class="sidebar">
    <div class="sidebar-inner">

      {%- set display_toc = page.toc.enable and display_toc %}
      {%- if display_toc %}
        {%- set toc = toc(page.content, { class: "nav", list_number: page.toc.number, max_depth: page.toc.max_depth }) %}
        {%- set display_toc = toc.length > 1 and display_toc %}
      {%- endif %}

      <ul class="sidebar-nav motion-element">
        <li class="sidebar-nav-toc">
          {{ __('sidebar.toc') }}
        </li>
        <li class="sidebar-nav-overview">
          {{ __('sidebar.overview') }}
        </li>
      </ul>

      <!--noindex-->
      <div class="post-toc-wrap sidebar-panel">
        {%- if display_toc %}
          <div class="post-toc motion-element">{{ toc }}</div>
        {%- endif %}
      </div>
      <!--/noindex-->

      <div class="site-overview-wrap sidebar-panel">
        {{ partial('_partials/sidebar/site-overview.swig', {}, {cache: theme.cache.enable}) }}

        {{- next_inject('sidebar') }}
      </div>

      {%- if theme.back2top.enable and theme.back2top.sidebar %}
        <div class="back-to-top motion-element">
          <i class="fa fa-arrow-up"></i>
          <span>0%</span>
        </div>
      {%- endif %}
	  {% if theme.recent_posts.enable %}
		<div class="links-of-blogroll scroll" style="margin-top:20px; border-style:dotted none none none; padding-top:5px; text-align:left;padding-left: 20px; padding-right: 10px; padding-bottom: 5px;">
		  <div class="links-of-blogroll-title" style="padding-bottom: 5px; padding-top: 5px; padding-left: 0px; padding-right: 20px; font-size: 1.6em; argin-right: 5px;">
		<!-- 选择合适的icon -->
		{%- if theme.recent_posts.icon %}<i class="{{ theme.recent_posts.icon }}" aria-hidden="true"></i>{%- endif %}
			<b style="font-size: 0.65em; padding-left: 8px; position: relative; top: -2px;">{{ theme.recent_posts.description }}</b>
		  </div>
		  <ul class="links-of-blogroll-list">
		<!-- 文章排序规格,-updated 按照文章更新时间倒排 -->
			{% set posts = site.posts.sort('updated').toArray() %}
		<!-- 显示10数目的文章 -->
			{% for post in posts.slice('0','10') %}
			  <li class="postsSidebarNumb" style="text-indent: -1em;">
				<a href="{{ url_for(post.path) }}" title="{{ post.title }}" target="_blank">{{ post.title }}</a>
			  </li>
			{% endfor %}
		  </ul>
		</div>
	  {% endif %}
	 
    </div>
	
  </aside>
  <div id="sidebar-dimmer"></div>
 
{% endmacro %}
