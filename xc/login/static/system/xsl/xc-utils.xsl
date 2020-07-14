<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:x="http://ai-and-it.de/xmlns/2020/xc"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns="http://ai-and-it.de/xmlns/2020/xc"
  version="1.0">

  <xsl:output method="xml" encoding="utf-8"/>

  <xsl:variable name="this" select="/"/>

  <xsl:template match="*" mode="to-xhtml">
    <xsl:element name="{local-name()}" namespace="http://www.w3.org/1999/xhtml">
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates mode="to-xhtml"/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="*" mode="to-xc">
    <xsl:element name="{local-name()}" namespace="http://ai-and-it.de/xmlns/2020/xc">
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates mode="to-xc"/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="x:*" mode="to-xc">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates mode="to-xc"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="x:offer" mode="to-xc">
    <offer data-new="{count($this/x:*/x:cont/x:*)}">
      <xsl:copy-of select="@*"/>
      <xsl:choose>
        <xsl:when test="$this/x:*/x:cont/x:address">
          <xsl:apply-templates select="$this/x:*/x:cont/x:address" mode="to-xc"/>
          <xsl:apply-templates select="x:calculation" mode="to-xc"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates mode="to-xc"/>
        </xsl:otherwise>
      </xsl:choose>
    </offer>
  </xsl:template>

  <xsl:template match="*">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="*" mode="copy">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates mode="copy"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="*" mode="get-text">
    <xsl:apply-templates mode="get-text"/>
  </xsl:template>

  <xsl:template name="select">
    <xsl:param name="val"/>
    <xsl:param name="def"/>
    <xsl:choose>
      <xsl:when test="$val">
        <xsl:apply-templates select="$val"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy-of select="$def"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="complete">
    <xsl:param name="exs"/>
    <xsl:param name="val"/>
    <xsl:param name="def"/>
    <xsl:if test="not($exs)">
      <xsl:call-template name="select">
        <xsl:with-param name="val" select="$val"/>
        <xsl:with-param name="def" select="$def"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <xsl:template name="pluralize">
    <xsl:param name="word"/>
    <xsl:param name="n"/>
    <xsl:param name="pend" select="'s'"/>
    <xsl:value-of select="$word"/>
    <xsl:if test="$n != 1">
      <xsl:value-of select="$pend"/>
    </xsl:if>
  </xsl:template>

  <xsl:template name="nitems">
    <xsl:param name="word"/>
    <xsl:param name="n"/>
    <xsl:param name="pend" select="'s'"/>
    <xsl:value-of select="$n"/>
    <xsl:text> </xsl:text>
    <xsl:call-template name="pluralize">
      <xsl:with-param name="word" select="$word"/>
      <xsl:with-param name="n" select="$n"/>
      <xsl:with-param name="pend" select="$pend"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template name="sitems">
    <xsl:param name="word"/>
    <xsl:param name="n"/>
    <xsl:param name="pend" select="'s'"/>
    <xsl:call-template name="pluralize">
      <xsl:with-param name="word" select="$word"/>
      <xsl:with-param name="n" select="2"/>
      <xsl:with-param name="pend" select="$pend"/>
    </xsl:call-template>
    <xsl:text> </xsl:text>
    <xsl:text>(</xsl:text>
    <xsl:value-of select="$n"/>
    <xsl:text>)</xsl:text>
  </xsl:template>

  <xsl:template match="*" mode="children">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="*" mode="children-to-xhtml">
    <xsl:apply-templates mode="to-xhtml"/>
  </xsl:template>

  <xsl:template match="x:cgi"/>

</xsl:stylesheet>
