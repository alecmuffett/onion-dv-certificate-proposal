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


## SOOC edge-cases, and "SOOC-EV"

It is necessary to recognise that there is one "weak" spot in the
assertion that string comparison is sufficient to prove the binding
between an Onion Address and a SSL Certificate Subject Alt-Name, and
that is in a scenario where the content webserver has been been
deployed on one (or more) machines which are separate from the machine
that terminates (ie: hosts) the Onion Address AND where the Tor daemon
makes direct TCP connections onwards to those servers.

The threat is: if a malicious actor can present themselves to the Tor
daemon as being the IP address of the server-side webserver, or
load-balancer, or as being one of the load-balanced server tier, then
under SOOC the malicious actor could create a certificate that would
permit them to impersonate a genuine SSL-certificate-enabled system
amongst that cloud.

This is a question of trust boundaries and real world deployments; at
the moment the "onion networking" service space is broadly comprised
of unencrypted HTTP, and as such any typical onion service deployment
which uses a load-balancer would already be at risk of this attack.

Contra: any onion site which uses a "rewriter" reverse-proxy (e.g.:
New York Times, Propublica) is typically NOT at risk from this attack,
because the inbound HTTPS request is terminated on the "onion" host,
immediately rewritten in terms of the address of the upstream service,
and is passed onward as a fresh HTTPS connection.

As far as I am aware, the only onion service deployment where this
would be a potential issue, is at Facebook; and if the Facebook devops
team are at risk of someone interposing a fake server and server
certificate into their infrastructure, then they have bigger problems
than mere onion service impersonation.

### Advanced Mitigations: SOOC-EV

Generally at this point, enthusiastic cryptographers will point at
Version 3 Onion Addresses and note that they are actual public keys,
and "couldn't they just sign the SOOC Certificate, and the browser
would check the signature, and that would be the end of the problem?"

They are correct to say this, however this raises two problems:

1. This would orphan Version 2 Onion addresses without SOOC, expressly
   against the intent of this document.

2. The Version 3 Onion addresses are (by Tor policy) never used to
   sign anything https://gitweb.torproject.org/torspec.git/tree/rend-spec-v3.txt#n557

Quote:

> Master (hidden service) identity key -- A master signing keypair
> used as the identity for a hidden service. This key is long term and
> not used on its own to sign anything; it is only used to generate
> blinded signing keys as described in [KEYBLIND]

In Version 3 Onion Addressing, the address-key is used to derive
short-term, time-locked, "blinded" keys in a fixed manner that can be
replicated by a client which wishes to connect to the master onion
address.  The blinded keys are used to sign connection information
that is loaded up into the "HSDir" distributed hash-table that
describes Onion connectivity.

Ergo: to implement a form of "Extended Validation" certificate
extension that would bind a TLS certificate to an onion address, the
certificate would have to contain the onion public key (for V2) or a
blinded public key for a reasonable timestamp (for V3), and this
public key would be used to validate a hash of some portion of the
certificate, all in order to address this niche deployment risk.

This is certainly possible to achieve, and is fairly straightforward,
however it is a tremendous hassle for a niche risk, and I believe that
it should not be an progress to implmenting SOOC without implementing
these "Extended Validation"-type checks.

My rationale for the deferring SOOC-EV development is - apart from the
nicheness aspect - bolstered by the observation that "Appendix F" of
CA/B-Forum Ballot 144:

https://cabforum.org/2015/02/18/ballot-144-validation-rules-dot-onion-names/

Describes the "CAB Forum Tor Service Descriptor Hash Extension", a
hash of the V2 Onion Public Key which Certificate Authorities are
obliged to bind into the EV TLS Onion Certificates that they issue,
ostensibly to both link the onion public key more tightly to the TLS
certificate in the event that a colliding V2 Onion address is
generated, but also to protect against the above described kinds of
attack.

I observe that no client code is implemented to check for this
condition, to the extent that when Digicert misissued a certificate
without the extension (compare https://crt.sh/?id=240277340 with
https://crt.sh/?id=241547157) nobody actually noticed.

As such, I don't believe that this attack is worthy of consideration
yet, especially as it is within the power of the service provider to
mitigate in alternative ways, and in any case we may still evolve
towards SOOC-EV as the the technology matures.

### Reciprocal Attack: Shared Tor Gateways?

Having comprehended the above, there is also obviously a reciprocal
risk which can be stated:

* What about shared onion gateways? What if many people use one Tor
  proxy to access Tor? One could interpose a fake SOCKS5
  man-in-the-middle and respond to Onion connection requests with a
  fake SOOC TLS certificate!

The response to which, again, is that although such may happen
experimentally, the overwhelming means by which people access Tor is
by using a local client over localhost, one (or more) per user. At the
"client" end, access to the Tor proxy is within the local trust
boundary, where worse things can happen.

# Linkfarm TBD

For more on Onion Networking as a layer-3 network, see:
https://www.youtube.com/watch?v=pebRZyg_bh8

IANA Special-Use Domain Names
https://www.iana.org/assignments/special-use-domain-names/special-use-domain-names.xhtml

Facebook Onion Announcement
https://www.facebook.com/notes/protect-the-graph/making-connections-to-facebook-more-secure/1526085754298237/

{backmatter}
