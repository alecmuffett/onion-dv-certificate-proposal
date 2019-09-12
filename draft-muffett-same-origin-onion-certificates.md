%%%
title = "Same Origin Onion Certificates"
abbrev = "sooc"
category = "info"
docName = "apparently this tool demands a doc name but does not use it"
ipr ="trust200902"
area = "Internet"
workgroup = "Transport Layer Security"
keyword = ["tor", "onion", "tls", "ssl"]

[seriesInfo]
status = "informational"
name = "Internet-Draft"
value = "draft-muffett-same-origin-onion-certificates-00"
stream = "IETF"

[[author]]
initials="A."
surname="Muffett"
fullname="Alec Muffett"
organization = "Independent"
  [author.address]
  email = "alec.muffett@gmail.com"
%%%

.# Abstract

WORK IN PROGRESS - SEPTEMBER 2019

Onion networking [@RFC7686] offers technical features which obviate
many of the risks upon which led to the development of our modern
Certificate Authority Public Key Infrastructure; as an increasingly
popular technology for networking with strong trust requirements,
onion networking would benefit from easier access to TLS certificates
for HTTPS use.

At the moment only EV certificates are available for onion network
addresses, although DV certificates are under discussion.  This
document defines a third mechanism - SOOC: Same Origin Onion
Certificates - which would enable real-time, client-side validation of
per-onion-address TLS certificates, fully equivalent (in defined
circumstances) to validation of a certificate trust chain, but
involving none of third parties, trust chains, or financial cost.

{mainmatter}

# Introduction

There are many reasons why the Internet and WWW are equipped with a
public key infrastructure (PKI), and the PKI offers many features and
benefits; however its inarguable primary function is to provide a form
of identity assurance, that when a person types a hostname such as
"www.example.com" into a web browser's URL bar, they should have some
reasonable expectation - and ideally a strong guarantee - that the
network-connected-service from which they are eventually served
content is one that would commonly be accepted as being capable,
permitted and expected to serve content which people who own the
"www.example.com" intentionally supply.

The PKI mechanism has evolved to provide such identity assurance in a
heavily-layered network environment which lacks overarching trust
mechanisms and which is riven with potential for attack at (or:
across) different layers.

For instance:

* ARP: first-hop, last-hop, or indeed any other hop may be hijacked
  with spoofed layer-2 address resolution; indeed some firewall
  devices rely upon this mechanism for their function
* TCP: traffic may be blocked, dropped, modified, injected, or
  redirected to fake machines
* BGP: bearer traffic and entire flows may be blocked, dropped, or
  redirected to fake machines
* DNS: namespaces can be domain-jacked, responses can be forged,
  cache-poisoned, or simply tampered-with in flight, also homoglyph
  "lookalike" domains (eg: www.examp1e.com) are also possible

The benefits of any intra-layer trust mechanism - eg: IPsec
Authentication Header (AH) & Encapsulating Security Payload (ESP) at
layer-3 - are typically isolated and not known to other layers of the
stack - eg: the web browser - which therefore cannot take
consideration of their benefits.

In this environment our HTTPS ecosystem has evolved in the expectation
of ignoring transport security - such as IPsec - and has instead has
built its own, where a server's "identity" may be provisionally
bootstrapped by DNS resolution of of a layer-3 IP address, however
that identity **MUST** be proven by proof-of-possession of a
cryptographic key that has been blessed by a trusted authority as
pertaining to "www.example.com".

The extent of such blessing is variable: for DV certificates the
requisite test is one of consistent DNS resolution (eg: LetsEncrypt);
and for EV certificates there are additional, expensive, and arguably
superfluous corporate identity checks.

## Onion Networking compared to TLS PKI

Tor "onion networking" is an alternate, software-defined, flat layer-3
network space which exists on top of TCP/IP and the rest of the
internet.

Onion addresses are either hashes of (in 80-bit version 2 addresses),
or are literally and entirely (in 256-bit version 3 addresses) the
public keys which sign all data that pertains to communication with
that address.

Like most cryptographic keys, onion addresses appear essentially to be
strings of random bits, although it's possible via "mining" to
eventually generate one which appears meaningful to human beings, eg:
"facebookcorewwwi.onion"

For purposes of PKI, the most interesting aspect of onion addresses is
their textual representation; unlike IPv4's "dotted quads" or IPv6's
colon-separated hexadecimal, onion addresses are required ([@RFC7686]
section 1) to be written in a DNS-compatible text format: as base-32
encoded binary with addition of the IANA Special-Use Domain Name
suffix, ".onion", and they are interpreted ignoring any labels other
than the rightmost two.

Thus: the onion address "www.exampleonionaddr.onion" would be a
version 2 onion address representing a server that possesses a
1024-bit RSA public key which has an 80-bit-truncated SHA-1 hash of
0x25c0c7ac8e6a1cd00c71 ([@RFC3548] base32 "EXAMPLEONIONADDR"); and
where the "www" prefix hostname/subdomain will ignored, although if
specified it will be passed onward in an HTTPS "Host:" header.

This representation pierces all of the layers of the network stack,
and in one encoding it addresses most of the problems which the TLS
PKI stack has gradually evolved to solve for TCP/IP:

* There is no DNS name resolution service in onion networking, and in
  fact [@RFC7686] section 2 specifies that there **MUST NOT** be
  overlap with DNS; this is an important point to which we will return
  later.
* What the user types into the browser bar will defacto prove what
  site they are connected to; the Tor Onion Network at layer 3 will
  consequently assert "proof-of-possession of a cryptographic key"
  that will correspond absolutely to the remote service; this is
  isomorphic to the model of a TLS certificate proving the identity of
  a webserver.
* Because onion addresses are layer-3 addresses, there is no concept
  of "subdomains" nor of "hostnames" and therefore any such
  information is considered "advisory"; however in this format they
  are backwards compatible in a way that "subdomains" for "dotted
  quad" addresses would not be, eg: "www.192.168.1.1"
* All other connectivity redirections or "hijacks" are inhibited by
  the Tor network stack.

# SOOC In Context

As described above, the security characteristics and protections of
layer-3 networking (eg: IPsec) are generally not visible to HTTPS
applications at layer-7, and therefore cannot be relied upon.

However: the encoding of onion addresses explicitly solves this problem:

* The connection **MUST** be an onion connection, because it was made
  using Tor-capable software, and because the ".onion" Special Use
  Domain Name is reserved for that purpose.
* The connection **MUST** be to "exampleonionaddr.onion" because the
  Tor network will not permit otherwise.
* Any subdomain or hostname is subordinate to the fact that the
  connection is made to "exampleonionaddr.onion", because (as a
  layer-3 address) there are actually no such things as "subdomains"
  or "hostnames", and thus this information is purely advisory, or for
  compatability.

Therefore it is possible for a client to assure itself - when
presented with a TLS certificate for "www.exampleonionaddr.onion" - to
assure itself that it is genuinely and authoritatively connected to
"exampleonionaddr.onion" by simply performing a string comparison with
the hostname to which is it connected - without any reference to a
certificate authority trust chain nor any other third party resource.

This observation is the basis of "Same Origin Onion Certificate"
checking; that onion sites may offer (eg: homebrew DV-compliant) TLS
certificates which correspond solely and uniquely to themselves, and
under those limited circumstances the client may skip the certificate
chain checks that might otherwise be required to validate identity.

# SOOC Conditions and Technical Definition

TODO

# SOOC Use Cases

TODO

## SOOC to complement, not replace, EV (and perhaps DV)

TODO

## SOOC and EV Certificates

TODO

## SOOC and DV Certificates

TODO

## SOOC and LetsEncrypt

TODO

## SOOC and HSTS

TODO

## SOOC and Certificate Transparency

TODO

# Linkfarm TBD

For more on Onion Networking as a layer-3 network, see:
https://www.youtube.com/watch?v=pebRZyg_bh8

IANA Special-Use Domain Names
https://www.iana.org/assignments/special-use-domain-names/special-use-domain-names.xhtml

Facebook Onion Announcement
https://www.facebook.com/notes/protect-the-graph/making-connections-to-facebook-more-secure/1526085754298237/

{backmatter}
