<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:fc="http://ai-and-it.de/xmlns/2020/fontcache"
  xmlns="http://ai-and-it.de/xmlns/2020/fontcache"
  version="1.0">

  <xsl:output method="xml" encoding="utf-8" indent="yes"/>

  <xsl:key name="byfile" use="fc:file" match="fc:entry"/>

  <xsl:template match="/">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="text()|*">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="fc:entry">
    <xsl:choose>
      <xsl:when test="preceding-sibling::fc:entry[1]/fc:Family != fc:Family
                      or preceding-sibling::fc:entry[1]/fc:Subfamily != fc:Subfamily">
        <xsl:copy>
          <xsl:copy-of select="@*"/>
          <xsl:attribute name="key">
            <xsl:value-of select="concat(fc:Family,'-',fc:Subfamily)"/>
          </xsl:attribute>
          <xsl:apply-templates/>
        </xsl:copy>
      </xsl:when>
      <xsl:otherwise>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
