# A simple proposal to provide DV certificates to Onion Sites

## Outline

[Onion sites](https://tools.ietf.org/html/rfc7686) provide self-authenticating network addresses which offer high assurance that a user of "onion networking" is connected to the service - strictly: to the possessor of a cryptographich private key - which they intended.

This degree of assurance in the TCP/IP network stack is provided by certificate authorities who provide various checks prior of issuance of a certificate to a website owner. Depending upon the nature of the end crtificate, some or all of these checks are redundant in the Onion networking space.

Onion-networking-enabled browsers are capable of delivering most, possibly all, of their streams-based services and user experiences over onion networking; this is evidenced by work at [Facebook](https://www.facebookcorewwwi.onion/) and the [New York Times](https://www.nytimes3xbfgragh.onion/), amongst others. These sites are equipped with EV certificates issued under the terms of [Ballot 144 of the CA/Browser Forum](https://cabforum.org/2015/02/18/ballot-144-validation-rules-dot-onion-names/) which opened up official provision for onion networking.

EV certificates are not available to individual users, and DV certificates are not available to onion addresses, for many reasons not least the justifiable liability concerns of Certificate Authorities; however the increasing popularity of onion networking, combined with the increasing number of applications which mandate use of HTTPS, leads towards a bifurcation of trust: that onion addresses offer high assurance, but there is no means for that to be leveraged in the HTTPS stack unless one is an organisation and capable of purchasing an EV certificate. This situation inhibits innovation in the network stack.

Also: there are considerations of HTTP/2, that in the TCP/IP network space, a single TCP connection which has been authenticated with a certificate offering SubjectAltNames of both `foo.com` and `bar.net`, will be treated as a pre-existing connection to `bar.net` for connection reuse even if the connection was originally made with the intention of fetching a resource from `foo.com`. It is probably that this level of trust may only be viable by provision of a licensed Certificate Authority as an arbiter.

However, this does not prohibit us from offering what we believe is a viable and simple solution for in-browser trust of DV certificates for onion addresses:

## Proposal

Consider a website with the onion address `examplewebsitexx.onion` offering services at URIs such as:

* `https://examplewebsitexx.onion`
* `https://www.examplewebsitexx.onion/foo.html`
* `https://m.staging.examplewebsitexx.onion/foo/bar.mp3`

A browser will consider a DV certificate to be valid for connections to this site, if one of the two following conditions is true:

### Condition 1:

* The connection certificate is a valid DV certificate (eg: such as those created by [Filippo Valsorda's `mkcert`](https://github.com/FiloSottile/mkcert) 
* **and** the certificate satisfies the existing standard trust rules for the webpage in question
* **and** the certificate is signed by a Certificate Authority Key which matches a root certificate that has been manually added to the local trust store

...or...

### Condition 2:

* The connection certificate is a valid DV certificate (eg: `mkcert`, again)
* and the certificate satisfies the existing standard trust rules for the webpage in question
* **but** the certificate is signed by a Certificate Authority Key that cannot be resolved in the local trust store
* **however** the rightmost two labels of **all Subject Alt Names in the certificate, without exception**, match those of the site (ie: `examplewebsitexx.onion`)
* **and** no Common Name is supplied on the certificate

## Rationale

Condition 1 has been extensively tested by the author, and is simple and obvious; extant web browsers do not take any special steps to avoid connections to `.onion` websites, and when connected to the Tor network they are abstracted from the network via a standard `SOCKS5` proxy which also performs name resolution, thereby obviating any DNS concerns.

Condition 2 is novel, but conceptually simple: to validate a DV certificate fully for connecting to a given site - including, eg: failing validation if not-before / not-after date boundaries are exceeded - *except* to selectively ignore failure to validate the certificate chain / an inability to resolve the Certificate Authority Key Identifier, in the circumstances that the certificate **could only ever be used to communicate with the given onion address/sitename**. 

The goal of requiring no Common Name is simply to be doubly-certain regarding potential for trust leaks; this may be redundant / is a matter for consideration.

I believe this proposal addresses the trust requirements of binding onion addresses to TLS certificates, preventing the issues of HTTP/2 connection reuse on the basis of Onion DV-certificates, and provides a self-serve route forwards for individuals to build-out onion services, via use of tools like `mkcert`.

This proposal also (currently) leaves open a non-exclusionary role[1] for existing EV Onion Certificates: for those purposes where more than one Onion address, or a mixture of Onion Addresses and DNS Names, **must** be present in a single certificate; at first consideration this would broadly be in line with the original vision of EV certificates as being "extra validated"

- Alec Muffett, 8 Feb 2019

[1] ie: individuals can work around it by careful provision of multiple certificates
