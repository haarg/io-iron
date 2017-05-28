package IO::Iron::PolicyBase::CharacterGroup;

## no critic (Documentation::RequirePodAtEnd)
## no critic (Documentation::RequirePodSections)
## no critic (Subroutines::RequireArgUnpacking)
## no critic (Variables::ProhibitPunctuationVars)

use 5.010_000;
use strict;
use warnings;

# Global creator
BEGIN {
    # Inherit nothing
}

# Global destructor
END {
}

=for stopwords config Mikko Koivunalho

=for stopwords alnum abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZ

=cut

# ABSTRACT: Base package (inherited) for IO::Iron::IronMQ/Cache/Worker::Policy packages.

# VERSION: generated by DZP::OurPkgVersion

use Log::Any  qw{$log};
use Params::Validate qw(:all);

=head1 SYNOPSIS

This class is for internal use only.

=cut

=head1 FUNCTIONS

=head2 group

Get the character group.

Parameters:

=over 8

=item character_group. Full group name, e.g. [:digit:].

=back

Return all characters as a string.

=cut

sub group {
    my %params = validate(
        @_, {
            'character_group' => { type => SCALAR, regex => qr/^[[:graph:]]+$/msx, }, # character group name.
        },
    );
    my ($group_name) = $params{'character_group'} =~ /\[:([[:graph:]]+):\]/msx;
    $log->tracef('group_name=%s;', $group_name);
    if($group_name eq 'alpha') { return alpha(); } ## no critic (ControlStructures::ProhibitCascadingIfElse)
    elsif($group_name eq 'alnum') { return alnum(); }
    elsif($group_name eq 'digit') { return digit(); }
    elsif($group_name eq 'lower') { return lower(); }
    elsif($group_name eq 'upper') { return upper(); }
    elsif($group_name eq 'word') { return word(); }
    else { return; }
}

=head2 alpha

Group [:alpha:], ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz.

=cut

sub alpha {
    return 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
            .'abcdefghijklmnopqrstuvwxyz';
}

=head2 alnum

Group [:alnum:], ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789.

=cut

sub alnum {
    return 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
        .'abcdefghijklmnopqrstuvwxyz'
        .'0123456789';
}

=head2 digit

Group [:digit:], 0123456789.

=cut

sub digit {
    return '0123456789';
}

=head2 lower

Group [:lower:], abcdefghijklmnopqrstuvwxyz.

=cut

sub lower {
    return 'abcdefghijklmnopqrstuvwxyz';
}

=head2 upper

Group [:upper:], ABCDEFGHIJKLMNOPQRSTUVWXYZ.

=cut

sub upper {
    return 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
}

=head2 word

Group [:word:], ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_.

=cut

sub word {
    return 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
            .'abcdefghijklmnopqrstuvwxyz'
            .'0123456789_';
}

1;

