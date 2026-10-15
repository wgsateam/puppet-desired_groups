Puppet::Type.newtype(:desired_groups) do
    @doc = "Adding user to existing system groups. Do nothing if group does not exist."

    desc "Adding user only to existing unix groups. Desired groups passed as parameter."

    autorequire(:user) do
        self[:name]
    end

    newparam(:name) do
        desc "The name of the user."
    end

    newproperty(:groups, :array_matching => :all) do
        desc "Desired groups list."

        # just pretty output on change methods
        def is_to_s( currentvalue )
            currentvalue.compact.join(',')
        end

        def should_to_s( newvalue )
            newvalue.compact.join(',')
        end

        # helper method
        def get_existing_groups
            groups = []
            # reset group iterator
            Etc.setgrent
            Etc.group {|g|
                groups << g.name
            }
            Etc.endgrent
            groups
        end

        # Skip groups that do not exist, checked when the resource is evaluated: munge
        # runs when the agent converts the catalog, before anything is applied, so a
        # group created earlier in the same run was added only on the next run.
        def should
            values = super
            return values if values.nil?
            existing = get_existing_groups
            values.map { |group| group if existing.include?(group) }
        end

        # The provider reports nil for every desired group the user is not in, so
        # compare with the filtered list, not with the declared one.
        def insync?(is)
            is.is_a?(Array) && is == should
        end
    end
end
