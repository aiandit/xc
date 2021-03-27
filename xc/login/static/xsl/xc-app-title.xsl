<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns="http://www.w3.org/1999/xhtml"
  version="1.0">

  <xsl:include href="xc.xsl"/>

  <xsl:output method="xml" encoding="utf-8"/>

  <xsl:template match="text()"/>

  <xsl:template match="text()" mode="xc-title"/>

  <xsl:template match="dict" mode="xc-title">XC</xsl:template>

  <xsl:template match="/">
    <xsl:apply-templates mode="xc-title"/>
  </xsl:template>

</xsl:stylesheet>
