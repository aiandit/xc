<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:x="http://ai-and-it.de/xmlns/2020/xc"
                xmlns:xhtml="http://www.w3.org/1999/xhtml"
                xmlns="http://www.w3.org/1999/xhtml"
                version="1.0">

  <xsl:output method="xml" encoding="utf-8"/>

  <xsl:include href="view-utils.xsl"/>

  <xsl:template match="x:item">
    <table style="display: inline-block;" class="actions">
      <tr><td>
        <a class="action" title="{x:path}/{x:name}"
           href="javascript:xc.performAction(event, '{x:name}')">
          <xsl:variable name="sname">
            <xsl:choose>
              <xsl:when test="starts-with(x:name, concat(/*/x:viewclass, '-'))">
                <xsl:value-of select="substring-after(x:name, concat(/*/x:viewclass, '-'))"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="x:name"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:value-of select="substring-before($sname, '.')"/>
        </a>
      </td>
      </tr>
    </table>
  </xsl:template>

  <xsl:template match="x:item" mode="create-doctype">
    <table style="display: inline-block;" class="actions">
      <tr><td>
        <a class="action" title="{x:path}/{x:name}"
           href="javascript:xc.createDoctype(event, '{x:path}/{x:name}')">
          <xsl:variable name="sname">
            <xsl:choose>
              <xsl:when test="starts-with(x:name, concat(/*/x:viewclass, '-'))">
                <xsl:value-of select="substring-after(x:name, concat(/*/x:viewclass, '-'))"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="x:name"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:value-of select="substring-before($sname, '.')"/>
        </a>
      </td>
      </tr>
    </table>
  </xsl:template>

  <xsl:template match="/">
    <div>
      <xsl:variable name="tf" select="/*/x:action-findlist/x:filters               /x:findlist/x:item"/>
      <xsl:variable name="tp" select="/*/x:action-findlist/x:pipelines             /x:findlist/x:item"/>
      <xsl:variable name="cf" select="/*/x:action-findlist/x:constructor-filters   /x:findlist/x:item"/>
      <xsl:variable name="cp" select="/*/x:action-findlist/x:constructor-pipelines /x:findlist/x:item"/>
      <xsl:variable name="t"  select="/*/x:action-findlist/x:types                 /x:findlist/x:item"/>
      <h4 class="oc-head">
        <xsl:call-template name="sitems">
          <xsl:with-param name="word" select="'Action'"/>
          <xsl:with-param name="n" select="count($tf)+count($tp)"/>
        </xsl:call-template> for item class <xsl:value-of select="/*/x:viewclass"/>
      </h4>
      <div>
        <xsl:attribute name="class">
          <xsl:choose>
            <xsl:when test="count($tf)+count($tp)">oc-body oc-open</xsl:when>
            <xsl:otherwise>oc-body</xsl:otherwise>
          </xsl:choose>
        </xsl:attribute>
        <h5 class="oc-head">
          <xsl:call-template name="sitems">
            <xsl:with-param name="word" select="'Pipeline'"/>
            <xsl:with-param name="n" select="count($tp)"/>
          </xsl:call-template>
        </h5>
        <div class="oc-body oc-open" data-display="inline">
          <xsl:attribute name="class">
            <xsl:choose>
              <xsl:when test="count($tp)">oc-body oc-open</xsl:when>
              <xsl:otherwise>oc-body</xsl:otherwise>
            </xsl:choose>
          </xsl:attribute>
          <xsl:apply-templates select="$tp"/>
        </div>
        <h5 class="oc-head">
          <xsl:call-template name="sitems">
            <xsl:with-param name="word" select="'Filter'"/>
            <xsl:with-param name="n" select="count($tf)"/>
          </xsl:call-template>
        </h5>
        <div class="oc-body">
          <xsl:apply-templates select="$tf"/>
        </div>
      </div>

      <h4 class="oc-head">
        <xsl:call-template name="sitems">
          <xsl:with-param name="word" select="'Constructor'"/>
          <xsl:with-param name="n" select="count($cf|$cp|$t)"/>
        </xsl:call-template>
      </h4>
      <div class="oc-body">
        <h5 class="oc-head">
          <xsl:call-template name="sitems">
            <xsl:with-param name="word" select="'Pipeline'"/>
            <xsl:with-param name="n" select="count($cp)"/>
          </xsl:call-template>
        </h5>
        <div class="oc-body" data-display="inline">
          <xsl:apply-templates select="$cp"/>
        </div>
        <h5 class="oc-head">
          <xsl:call-template name="sitems">
            <xsl:with-param name="word" select="'Filter'"/>
            <xsl:with-param name="n" select="count($cf)"/>
          </xsl:call-template>
        </h5>
        <div class="oc-body">
          <xsl:apply-templates select="$cf"/>
        </div>
        <h5 class="oc-head">
          <xsl:call-template name="sitems">
            <xsl:with-param name="word" select="'Doctype'"/>
            <xsl:with-param name="n" select="count($t)"/>
          </xsl:call-template>
        </h5>
        <div class="oc-body">
          <xsl:apply-templates mode="create-doctype" select="$t"/>
        </div>
      </div>

    </div>
  </xsl:template>

</xsl:stylesheet>
