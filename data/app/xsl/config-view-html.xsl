<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns:x="http://ai-and-it.de/xmlns/2020/xc"
  xmlns="http://www.w3.org/1999/xhtml"
  version="1.0">

  <xsl:output method="xml" encoding="utf-8"/>

  <xsl:template match="text()"/>

  <xsl:template match="/">
    <div>
      <ul>
        <xsl:apply-templates/>
      </ul>
    </div>
  </xsl:template>
  
  <xsl:template match="x:*">
    <li>
      <b>Element <xsl:value-of select="name()"/></b>
      <xsl:if test="@*">
        <span class="bo">[</span>
        <xsl:for-each select="@*">
          <xsl:if test="position()>1">
            <span class="acol">;</span>
          </xsl:if>
          <span class="aname">
            <xsl:value-of select="name()"/>
          </span>
          <span class="asep">=</span>
          <span class="aval">
            <xsl:value-of select="."/>
          </span>
        </xsl:for-each>
        <span class="bc">]</span>
      </xsl:if>
      <xsl:choose>
        <xsl:when test="x:*">
          <ul>
            <xsl:apply-templates select="x:*"/>
          </ul>
        </xsl:when>
        <xsl:when test="normalize-space()">
          <span class="esep">=</span>
          <b class="tval">
            <xsl:value-of select="."/>
          </b>
        </xsl:when>
      </xsl:choose>
    </li>
  </xsl:template>

  <xsl:template match="x:cgi/x:cgi">
    <xsl:apply-templates/>
  </xsl:template>
  
  <xsl:template match="x:cgi">
    <div>
      <h3 class="oc-head">Form</h3>
      <div class="oc-body">
        <h5>Form parameters</h5>
        <ul>
          <xsl:for-each select="x:*">
            <xsl:apply-templates select="."/>
          </xsl:for-each>
        </ul>
      </div>
    </div>
  </xsl:template>

  <xsl:template match="x:clock">
    <div class="clock">
      <h3 class="oc-head">Clock</h3>
      <div class="oc-body oc-open">
        <h5>Switch</h5>
        <div id="poll-clock-{generate-id()}"
             class="xc-sl-poll"
             data-poll-url="/main/plain_status?path=bin/date.sh"
             data-poll-target="poll-clock-{generate-id()}"
             data-postprocess="xc.id"
             >
          Clock here
        </div>
        <ul>
          <xsl:for-each select="x:*">
            <xsl:apply-templates select="."/>
          </xsl:for-each>
        </ul>
      </div>
    </div>
  </xsl:template>

  <xsl:template match="x:env">
    <div class="env">
      <h3 class="oc-head">Environment</h3>
      <div class="oc-body oc-open">
        <h5>Switch</h5>
        <div id="poll-clock-{generate-id()}"
             class="xc-sl-poll pre"
             data-poll-url="/main/plain_status?path=bin/env.sh"
             data-poll-target="poll-clock-{generate-id()}"
             data-poll-interval="12"
             data-postprocess="xc.id"
             >
          env here
        </div>
        <ul>
          <xsl:for-each select="x:*">
            <xsl:apply-templates select="."/>
          </xsl:for-each>
        </ul>
      </div>
    </div>
  </xsl:template>

</xsl:stylesheet>
