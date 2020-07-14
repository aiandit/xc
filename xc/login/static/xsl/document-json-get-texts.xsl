<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:x="http://ai-and-it.de/xmlns/2020/xc"
  version="1.0">

  <xsl:output method="text"/>

  <xsl:template match="text()"/>

  <xsl:template match="/">
    <xsl:variable name="json">
     <xsl:apply-templates/>
    </xsl:variable>
    <xsl:text> { </xsl:text>
    <xsl:value-of select="substring($json, 2)"/>
    <xsl:text> } </xsl:text>
  </xsl:template>

  <xsl:template match="text()" mode="asjson"/>
  <xsl:template match="text()" mode="asjson-de"/>

  <xsl:template match="/" mode="textid"/>
  <xsl:template match="x:letter|x:body|x:address|x:table|x:texts" mode="textid-p"/>
  <xsl:template match="*" mode="textid-p">
    <xsl:apply-templates select="." mode="textid"/>
  </xsl:template>

  <xsl:template match="*" mode="textid">
    <xsl:variable name="psn" select="preceding-sibling::x:*[name()=name(current())]"/>
    <xsl:variable name="pid">
      <xsl:apply-templates select=".." mode="textid-p"/>
    </xsl:variable>
    <xsl:if test="string-length($pid)>0">
      <xsl:value-of select="$pid"/>
      <xsl:text>.</xsl:text>
    </xsl:if>
    <xsl:value-of select="name()"/>
    <xsl:value-of select="count($psn)+1"/>
  </xsl:template>

  <xsl:template match="*" mode="asjson-de">
    <xsl:text>, "</xsl:text>
    <xsl:apply-templates select="." mode="textid"/>
    <xsl:text>": </xsl:text>
    <xsl:apply-templates select="." mode="asjson"/>
  </xsl:template>

  <xsl:template match="*" mode="asjson">
    <xsl:text> { "name": "</xsl:text>
    <xsl:apply-templates select="." mode="textid"/>
    <xsl:text>", "class": "</xsl:text>
    <xsl:value-of select="@class"/>
    <xsl:text>", "text": "</xsl:text>
    <xsl:value-of select="normalize-space(.)"/>" }
  </xsl:template>

  <xsl:template match="*" mode="asjson-ae">
    <xsl:text>,</xsl:text>
    <xsl:apply-templates select="." mode="asjson"/>
  </xsl:template>

  <xsl:template match="x:texts">
    <xsl:apply-templates mode="asjson-de"/>
  </xsl:template>

  <xsl:template match="x:address">
    <xsl:text>, "</xsl:text>
    <xsl:apply-templates select="." mode="textid"/>
    <xsl:text>": </xsl:text>
    <xsl:variable name="json">
     <xsl:apply-templates mode="asjson-de"/>
    </xsl:variable>
    <xsl:text> { </xsl:text>
    <xsl:value-of select="substring($json, 2)"/>
    <xsl:text> } </xsl:text>
  </xsl:template>

  <xsl:template match="x:p|x:div">
    <xsl:apply-templates select="." mode="asjson-ae"/>
  </xsl:template>

  <xsl:template match="x:body">
    <xsl:text>, "</xsl:text>
    <xsl:apply-templates select="." mode="textid"/>
    <xsl:text>": </xsl:text>
    <xsl:variable name="json">
      <xsl:apply-templates/>
    </xsl:variable>
    <xsl:text> [ </xsl:text>
    <xsl:value-of select="substring($json, 2)"/>
    <xsl:text> ] </xsl:text>
  </xsl:template>

  <xsl:template match="x:table">
    <xsl:text>, { "name": "</xsl:text>
    <xsl:apply-templates select="." mode="textid"/>
    <xsl:text>", "entries": </xsl:text>
    <xsl:variable name="json">
      <xsl:apply-templates/>
    </xsl:variable>
    <xsl:text> { </xsl:text>
    <xsl:value-of select="substring($json, 2)"/>
    <xsl:text> } </xsl:text>
    <xsl:text> } </xsl:text>
  </xsl:template>

  <xsl:template match="x:td">
    <xsl:apply-templates select="." mode="asjson-de"/>
  </xsl:template>

</xsl:stylesheet>
