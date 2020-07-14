<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:x="http://ai-and-it.de/xmlns/2020/xc"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns="http://www.w3.org/1999/xhtml"
  version="1.0">

  <xsl:output method="xml" encoding="utf-8"/>

  <xsl:param name="template-doc-uri" select="'/main/getf/templates/html/msgs.html'"/>
  <xsl:param name="template-doc" select="document($template-doc-uri)"/>

  <xsl:variable name="this" select="/"/>

  <xsl:include href="view-utils.xsl"/>

  <xsl:template match="text()"/>

  <xsl:template match="/">
    <div>
      <xsl:apply-templates/>
    </div>
  </xsl:template>

  <xsl:template match="x:msgs">
    <div class="msgs">
      <xsl:apply-templates/>
    </div>
  </xsl:template>

  <xsl:template match="x:msg">
    <div>
      <xsl:attribute name="class">
        <xsl:text>msg</xsl:text>
        <xsl:if test="x:own>0">
          <xsl:text> own</xsl:text>
        </xsl:if>
      </xsl:attribute>
      <div>
        <xsl:if test="not(x:own>0)">
          <div class="msg-from">
            <xsl:apply-templates select="x:from/node()" mode="to-xhtml"/>
          </div>
        </xsl:if>
      </div>
      <div class="msg-text">
        <xsl:apply-templates select="x:text/node()" mode="to-xhtml"/>
        <div class="msg-time">
          <span class="unixtm">
            <xsl:apply-templates select="x:time/node()" mode="get-text"/>
          </span>
        </div>
      </div>
    </div>
  </xsl:template>

  <xsl:template match="x:msg/x:text">
    <xsl:apply-templates/>
  </xsl:template>

</xsl:stylesheet>
