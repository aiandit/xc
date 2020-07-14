<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:x="http://ai-and-it.de/xmlns/2020/xc"
                xmlns="http://ai-and-it.de/xmlns/2020/xc"
  version="1.0">

  <xsl:output method="xml"/>

  <xsl:template match="/">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

  <!--  <xsl:template match="tradeitem/cost"/> -->

  <xsl:template match="x:cgi"/>

  <xsl:template match="x:tradeitem">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates/>
      <xsl:if test="not(x:cost)">
        <cost>
          <xsl:value-of select="x:amount*x:price"/>
        </cost>
      </xsl:if>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
