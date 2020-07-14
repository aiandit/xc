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

  <xsl:template match="x:cgi"/>

  <xsl:template match="*" mode="as-price">
    <span class="price">
      <span class="number">
        <xsl:value-of select="format-number(., '0.00')"/>
      </span>
      <span class="curs">
        <xsl:value-of select="ancestor-or-self::*/x:cur"/>
      </span>
    </span>
  </xsl:template>

  <xsl:template match="*" mode="as-number">
    <span class="number">
      <xsl:value-of select="number(.)"/>
    </span>
  </xsl:template>

  <xsl:template match="x:calculation">
    <table>

      <tr>
        <td></td>
        <td class="aleft">Posten</td>
        <td class="aright">
          Anzahl
        </td>
        <td class="aright">
          Preis
        </td>
        <td class="aright">
          Gesamt
        </td>
      </tr>

      <xsl:for-each select="x:tradeitem">
        <tr>
          <td class="aleft" style="width:1.8em;">
            <xsl:number format="0"/>.
          </td>
          <td>
            <xsl:value-of select="x:desc"/>
          </td>
          <td class="aright ntd">
            <xsl:apply-templates select="x:amount" mode="as-number"/>
          </td>
          <td class="aright ntd">
            <xsl:apply-templates select="x:price" mode="as-price"/>
          </td>
          <td class="aright ntd">
            <xsl:apply-templates select="x:cost" mode="as-price"/>
          </td>
        </tr>
      </xsl:for-each>

      <tr>
        <td>
        </td>
        <td>
          Netto
        </td>
        <td>
        </td>
        <td>
        </td>
        <td class="aright">
          <xsl:apply-templates select="x:sum-netto" mode="as-price"/>
        </td>
      </tr>

      <tr>
        <td>
        </td>
        <td>USt. <xsl:value-of select="x:uststz*100"/>%</td>
        <td>
        </td>
        <td>
        </td>
        <td class="aright">
          <xsl:apply-templates select="x:sum-taxes" mode="as-price"/>
        </td>
      </tr>

      <tr>
        <td>
        </td>
        <td class="aleft">
          Brutto
        </td>
        <td>
        </td>
        <td>
        </td>
        <td class="aright">
          <b>
            <xsl:apply-templates select="x:sum-brutto" mode="as-price"/>
          </b>
        </td>
      </tr>
    </table>
  </xsl:template>

</xsl:stylesheet>
