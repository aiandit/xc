<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:x="http://ai-and-it.de/xmlns/2020/xc"
                xmlns="http://ai-and-it.de/xmlns/2020/xc"
  version="1.0">

  <xsl:output method="xml"/>

  <xsl:include href="copy.xsl"/>

  <xsl:template match="/">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="x:sum-netto|x:sum-brutto|x:sum-taxes"/>

  <xsl:template match="x:calculation">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates/>
      <xsl:variable name="sum-netto" select="sum(x:tradeitem/x:cost)"/>
      <sum-netto>
        <xsl:value-of select="$sum-netto"/>
      </sum-netto>
      <sum-taxes>
        <xsl:value-of select="$sum-netto * x:uststz"/>
      </sum-taxes>
      <sum-brutto>
        <xsl:value-of select="$sum-netto * (1 + x:uststz)"/>
      </sum-brutto>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
