// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SocialMedia {
    // Events
    event PostCreated(uint256 indexed postId, address indexed author, string content, uint256 timestamp);
    event PostLiked(uint256 indexed postId, address indexed liker, uint256 totalLikes);
    event UserFollowed(address indexed follower, address indexed following);
    event UserUnfollowed(address indexed follower, address indexed following);
    event ProfileUpdated(address indexed user, string username, string bio);

    // Structs
    struct Post {
        uint256 id;
        address author;
        string content;
        uint256 timestamp;
        uint256 likes;
        bool exists;
    }

    struct UserProfile {
        string username;
        string bio;
        uint256 postCount;
        uint256 followersCount;
        uint256 followingCount;
        bool exists;
    }

    // State Variables
    mapping(uint256 => Post) public posts;
    mapping(address => UserProfile) public profiles;
    mapping(address => mapping(address => bool)) public isFollowing;
    mapping(uint256 => mapping(address => bool)) public hasLiked;
    mapping(address => uint256[]) public userPosts;
    
    uint256 public totalPosts;
    uint256 public totalUsers;

    // Modifiers
    modifier userExists() {
        require(profiles[msg.sender].exists, "User profile does not exist");
        _;
    }

    modifier postExists(uint256 _postId) {
        require(posts[_postId].exists, "Post does not exist");
        _;
    }

    // Function 1: Create User Profile
    function createProfile(string memory _username, string memory _bio) external {
        require(!profiles[msg.sender].exists, "Profile already exists");
        require(bytes(_username).length > 0, "Username cannot be empty");
        require(bytes(_username).length <= 50, "Username too long");
        require(bytes(_bio).length <= 200, "Bio too long");

        profiles[msg.sender] = UserProfile({
            username: _username,
            bio: _bio,
            postCount: 0,
            followersCount: 0,
            followingCount: 0,
            exists: true
        });

        totalUsers++;
        emit ProfileUpdated(msg.sender, _username, _bio);
    }

    // Function 2: Create Post
    function createPost(string memory _content) external userExists {
        require(bytes(_content).length > 0, "Post content cannot be empty");
        require(bytes(_content).length <= 500, "Post content too long");

        totalPosts++;
        
        posts[totalPosts] = Post({
            id: totalPosts,
            author: msg.sender,
            content: _content,
            timestamp: block.timestamp,
            likes: 0,
            exists: true
        });

        userPosts[msg.sender].push(totalPosts);
        profiles[msg.sender].postCount++;

        emit PostCreated(totalPosts, msg.sender, _content, block.timestamp);
    }

    // Function 3: Like/Unlike Post
    function toggleLike(uint256 _postId) external userExists postExists(_postId) {
        require(posts[_postId].author != msg.sender, "Cannot like your own post");

        if (hasLiked[_postId][msg.sender]) {
            // Unlike the post
            hasLiked[_postId][msg.sender] = false;
            posts[_postId].likes--;
        } else {
            // Like the post
            hasLiked[_postId][msg.sender] = true;
            posts[_postId].likes++;
        }

        emit PostLiked(_postId, msg.sender, posts[_postId].likes);
    }

    // Function 4: Follow User
    function followUser(address _userToFollow) external userExists {
        require(_userToFollow != msg.sender, "Cannot follow yourself");
        require(profiles[_userToFollow].exists, "User to follow does not exist");
        require(!isFollowing[msg.sender][_userToFollow], "Already following this user");

        isFollowing[msg.sender][_userToFollow] = true;
        profiles[msg.sender].followingCount++;
        profiles[_userToFollow].followersCount++;

        emit UserFollowed(msg.sender, _userToFollow);
    }

    // Function 5: Unfollow User
    function unfollowUser(address _userToUnfollow) external userExists {
        require(_userToUnfollow != msg.sender, "Cannot unfollow yourself");
        require(profiles[_userToUnfollow].exists, "User to unfollow does not exist");
        require(isFollowing[msg.sender][_userToUnfollow], "Not following this user");

        isFollowing[msg.sender][_userToUnfollow] = false;
        profiles[msg.sender].followingCount--;
        profiles[_userToUnfollow].followersCount--;

        emit UserUnfollowed(msg.sender, _userToUnfollow);
    }

    // View Functions
    function getPost(uint256 _postId) external view returns (
        uint256 id,
        address author,
        string memory content,
        uint256 timestamp,
        uint256 likes
    ) {
        require(posts[_postId].exists, "Post does not exist");
        Post memory post = posts[_postId];
        return (post.id, post.author, post.content, post.timestamp, post.likes);
    }

    function getUserPosts(address _user) external view returns (uint256[] memory) {
        return userPosts[_user];
    }

    function getProfile(address _user) external view returns (
        string memory username,
        string memory bio,
        uint256 postCount,
        uint256 followersCount,
        uint256 followingCount
    ) {
        require(profiles[_user].exists, "User profile does not exist");
        UserProfile memory profile = profiles[_user];
        return (profile.username, profile.bio, profile.postCount, profile.followersCount, profile.followingCount);
    }

    function checkIfLiked(uint256 _postId, address _user) external view returns (bool) {
        return hasLiked[_postId][_user];
    }

    function checkIfFollowing(address _follower, address _following) external view returns (bool) {
        return isFollowing[_follower][_following];
    }
}
